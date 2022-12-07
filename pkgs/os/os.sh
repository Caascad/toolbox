#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

export VAULT_FORMAT="json"
CONFIG="${HOME}/.config/caascad"
OS_CONFIG="${CONFIG}/os"
CAASCAD_ZONES_URL=${CAASCAD_ZONES_URL:-https://git.corp.caascad.com/caascad/terraform/envs-ng/-/raw/master/gen/zones_static/zones_short.json}
CAASCAD_ZONES_FILE="${CONFIG}/caascad-zones.json"
CURRENT_FILE="${OS_CONFIG}/current"
HIDE=false
OSC_DEBUG=${OSC_DEBUG:-0}

_help() {
    cat <<EOF
NAME
      Thin wrapper around openstack command

SYNOPSIS
      os [os-command] [environment]
      os <openstack subcommand>

DESCRIPTION
      <empty>
            Prints the environment selected

      os_help | ch
            Prints this help

      switch | s
            Change the environment selected to issue openstack commands

      print | p [-u] [-e]
            Prints openstack environment variables used.
            Obfuscates password unless -u parameter is used.

      support-template | st
            Prints a mail support template with all necessary informations pre-filled

      <openstack-subcommand>
            Standard openstack subcommands, token issue, server list

EOF
}

_init() {
    mkdir -p "${OS_CONFIG}"
    touch "${CURRENT_FILE}"
    _refresh
}

_is_local () {
  [[ -f "$1" ]]
}

_refresh() {
    if _is_local "${CAASCAD_ZONES_URL}"; then
      cp "${CAASCAD_ZONES_URL}" "${CAASCAD_ZONES_FILE}"
    else
      curl -s "${CAASCAD_ZONES_URL}" -o "${CAASCAD_ZONES_FILE}"
    fi
}

_switch() {
    ZONE="${1}"
    echo "${ZONE}" > "${CURRENT_FILE}"
    _refresh
    _check_zone "${ZONE}"
}

_check_zone() {
  ZONE=${1}
  if ! jq -e -r --arg ZONE "${ZONE}" '.[] | select(.providers.fe.domain.name == $ZONE) | .infra_zone_name' "${CAASCAD_ZONES_FILE}" &>/dev/null && 
    ! jq -e -r --arg ZONE "${ZONE}" '.[$ZONE].infra_zone_name' "${CAASCAD_ZONES_FILE}" &>/dev/null; then
    echo "Zone or domain name ${ZONE} not found" >&2 && exit 1;
  fi
}

_get_vault_fqdn() {
  ZONE="${1}"
  if [[ $ZONE_NAME =~ ^OCB000.* ]]; then
      INFRA_ZONE_NAME="$(jq -e -r --arg ZONE "${ZONE}" '.[] | select(.providers.fe.domain.name == $ZONE) | .infra_zone_name' "${CAASCAD_ZONES_FILE}" )"
      DOMAIN_NAME="$(jq -r --arg ZONE "${INFRA_ZONE_NAME}" '.|to_entries[] | select(.key == $ZONE) | .value.domain_name' "${CAASCAD_ZONES_FILE}" )"
  else
      INFRA_ZONE_NAME="$(jq -e -r --arg ZONE "${ZONE}" '.[$ZONE].infra_zone_name' "${CAASCAD_ZONES_FILE}")"
      DOMAIN_NAME="$(jq -r --arg INFRA_ZONE_NAME "${INFRA_ZONE_NAME}" '.[$INFRA_ZONE_NAME].domain_name' "${CAASCAD_ZONES_FILE}")"
  fi
  echo "https://vault.${INFRA_ZONE_NAME}.${DOMAIN_NAME}"
}

_get_current_zone() {
  ZONE=$(cat "${CURRENT_FILE}")
  if [ -z "${ZONE}" ]; then
    echo "Zone name empty. Use os switch first." >&2
    exit 1
  fi
  _check_zone "${ZONE}"
  echo "${ZONE}"
}

_parse() {
    if [[ "$#" -eq 0 ]]; then
      _help
      exit 0;
    fi
    case "$1" in
        os_help|ch)
            _help
            ;;
        print|p)
            _print "${@:2}"
            ;;
        support-template|st)
            _get_secrets
            _support_template
            ;;
        refresh|r)
            _refresh;
            ;;
        switch|s)
            if [[ "${#}" -eq 1 ]] ; then
                _get_current_zone
            elif [[ "${#}" -eq 2 ]]; then
                _switch "${2}"
            else
                echo "switch subcommand needs 1 argument"
            fi
            ;;
        *)
            _get_secrets
            openstack "$@"
            ;;
    esac
}

_print() {
    HIDE=true
    EXPORT=false
    while [[ $# -gt 0 ]]; do
      case ${1} in
        -u)
          HIDE=false
          shift
          ;;
        -e)
          EXPORT=true
          shift
          ;;
        *)
          exit 1
          ;;
      esac
    done
    _get_secrets
    OSVARS=$(env | grep -e ^OS_)
    if "${EXPORT}"; then
      OSVARS=${OSVARS//OS/export OS}
    fi
    echo "${OSVARS}"
}
_support_template() {
    CLUSTER_IDS=()
    CLUSTER_IDS=($(openstack cce cluster list -c ID -f value))
    if [ ${#CLUSTER_IDS[@]} -gt 1 ]; then
      echo "We need only one cluster. We will print all clusters we have found"
      CLUSTER_ID=${CLUSTER_IDS[*]}
    else
      CLUSTER_ID=${CLUSTER_IDS[0]}
    fi

    INFOS=($(openstack project show "${OS_PROJECT_NAME}" -f value -c domain_id -c id))
    DOMAIN_ID=${INFOS[0]}
    PROJECT_ID=${INFOS[1]}

    cat <<EOF

Hello,

We encounter an issue on the following CCE cluster:

cluster_id: ${CLUSTER_ID}
domain id: ${DOMAIN_ID}
domain name: ${OS_USER_DOMAIN_NAME}
project id: ${PROJECT_ID}
project name: ${OS_PROJECT_NAME}
tenant id: ${PROJECT_ID}

<describe the problem here>

Regards,
EOF
}

_get_secrets() {
    ZONE_NAME=$(_get_current_zone)
    VAULT_ADDR=$(_get_vault_fqdn "${ZONE_NAME}")
    export VAULT_ADDR
    if [ "${OSC_DEBUG}" -ne 0 ]; then
      >&2 echo "Using ${VAULT_ADDR}"
      >&2 echo "Looking for ${ZONE_NAME} secrets"
    fi
    if [[ $ZONE_NAME =~ ^OCB000.* ]]; then
        secret=$(vault read secret/zones/fe/api-"${ZONE_NAME}")
    else
        secret=$(vault read secret/zones/fe/"${ZONE_NAME}"/api)
    fi
    OS_AUTH_URL=https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3
    OS_USERNAME=$(echo "$secret"| jq -r .data.username)
    OS_PROJECT_NAME=$(echo "$secret"| jq -r .data.tenant_name)
    OS_USER_DOMAIN_NAME=$(echo "$secret"| jq -r .data.domain_name)
    OS_IDENTITY_API_VERSION=3
    OS_IMAGE_API_VERSION=2
    OS_INTERFACE=public
    NOVA_ENDPOINT_TYPE=publicURL
    OS_ENDPOINT_TYPE=publicURL
    CINDER_ENDPOINT_TYPE=publicURL
    OS_VOLUME_API_VERSION=2
    OS_PASSWORD=$(
      if "${HIDE}"; then
        echo "XXX"
      else
        echo "$secret"| jq -r .data.password
      fi
    )
    OS_REGION_NAME=$(echo "$secret"| jq -r .data.region)
    export OS_AUTH_URL \
           OS_USERNAME \
           OS_PROJECT_NAME \
           OS_USER_DOMAIN_NAME \
           OS_IDENTITY_API_VERSION \
           OS_IMAGE_API_VERSION \
           OS_INTERFACE \
           NOVA_ENDPOINT_TYPE \
           OS_ENDPOINT_TYPE \
           CINDER_ENDPOINT_TYPE \
           OS_VOLUME_API_VERSION \
           OS_PASSWORD OS_REGION_NAME 
}

_init
_parse "$@"
