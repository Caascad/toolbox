#!/usr/bin/env bash

set -euo pipefail
CAASCAD_OPENSTACK_TRACE="${CAASCAD_OPENSTACK_TRACE:-0}"

if [ "${CAASCAD_OPENSTACK_TRACE}" -eq 1 ]; then set -x; fi

export VAULT_FORMAT="json"
CONFIG="${HOME}/.config/caascad"
OS_CONFIG="${CONFIG}/os"
CAASCAD_ZONES_URL="https://git.corp.cloudwatt.com/caascad/caascad-zones/raw/master/zones.json"
CAASCAD_ZONES_FILE="${CONFIG}/caascad-zones.json"
CURRENT_FILE="${OS_CONFIG}/current"

_help() {
    cat <<EOF
NAME
      Thin wrapper around openstack command

SYNOPSIS
      caascad-openstack [os-command] [environment]
      caascad-openstack <openstack subcommand>

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

      <openstack-subcommand>
            Standard openstack subcommands, token issue, server list

    }
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
    echo "${1}" > "${CURRENT_FILE}"
}

_parse() {
    if [[ "$#" -eq 0 ]]; then
        cat "${CURRENT_FILE}";
        exit 0;
    fi
    case "$1" in
        os_help|ch)
            _help
            ;;
        print|p)
            _get_secrets
            _print "${@:2}"
            ;;
        refresh|r)
            _refresh;
            ;;
        switch|s)
            if [[ "$#" -eq 2 ]]; then
                _switch "$2"
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
    OSVARS=$(env | grep -e ^OS_)
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
      esac
    done
    if "${HIDE}";  then
      # shellcheck disable=SC2001
      OSVARS=$(echo "${OSVARS}"| sed 's/OS_PASSWORD=.*/OS_PASSWORD=XXX/g')
    fi
    if "${EXPORT}"; then
      # shellcheck disable=SC2001
      OSVARS=$(echo "${OSVARS}"| sed 's/\(^.*=.*$\)/export \1/g')
    fi
    echo "${OSVARS}"
}

_get_secrets() {
    ZONE_NAME=$(cat "${CURRENT_FILE}")
    export ZONE_NAME
    [ -z "${ZONE_NAME}" ] && echo "No environment selected. Use 'caascad-openstack switch <env> first.'" && exit 1
    if [[ $ZONE_NAME =~ ^OCB000.* ]]; then
        INFRA_ZONE_NAME="$(jq -r '.[] | select(.providers.fe.domain_name == env.ZONE_NAME) | .name' < "${CAASCAD_ZONES_FILE}" )"
        DOMAIN_NAME="$(jq -r '.[] | select(.providers.fe.domain_name == env.ZONE_NAME) | .domain_name' < "${CAASCAD_ZONES_FILE}" )"
    else
        INFRA_ZONE_NAME="$(jq -r '.[env.ZONE_NAME].infra_zone_name' < "${CAASCAD_ZONES_FILE}")"
        DOMAIN_NAME="$(jq -r '.[env.ZONE_NAME].domain_name' < "${CAASCAD_ZONES_FILE}")"
    fi
    export VAULT_ADDR="https://vault.${INFRA_ZONE_NAME}.${DOMAIN_NAME}"
    >&2 echo "Using ${VAULT_ADDR}"
    >&2 echo "Looking for ${ZONE_NAME} secrets"
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
    OS_PASSWORD=$(echo "$secret"| jq -r .data.password)
    OS_REGION_NAME=$(echo "$secret"| jq -r .data.region)
    export VAULT_ADDR \
           OS_AUTH_URL \
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
