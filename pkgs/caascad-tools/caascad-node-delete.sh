#!/usr/bin/env bash
set -euo pipefail

CAASCAD_NODE_DELETE_TRACE=${DL_NODE_TRACE:-0}
if [ "${CAASCAD_NODE_DELETE_TRACE}" -eq 1 ]; then set -x; fi

function _help () {
  cat <<EOF
NAME
      Helper to delete a node on any cloud provider

SYNOPSIS
      caascad-node-delete <ZONE> <NODE> [ -h ]

      -h
            Display this help

EXAMPLES

      $ caascad-node-delete bravo 10.11.12.13

      $ CAASCAD_NODE_DELETE_TRACE=1 caascad-node-delete janeway ip-10-11-12-13.eu-west-3.compute.internal
EOF

}

function delete_fe () {
  INSTANCE_ID="${1}"
  # shellcheck disable=SC2207
  CLUSTER_LIST=($(openstack cce cluster list -f value -c ID))
  for CLUSTER_ID in ${CLUSTER_LIST[*]}; do
    openstack cce cluster node list "${CLUSTER_ID}" | grep -q "${INSTANCE_ID}"
    # shellcheck disable=SC2181
    if [ "${?}" -eq 0 ]; then break; fi
  done
  openstack cce cluster node delete "${CLUSTER_ID}" "${INSTANCE_ID}"
}

function delete_aws () {
  env|grep "AWS"
  aws ec2 terminate-instances --instance-id "${1}"
}

function auth_fe () {
  eval "$(caascad-openstack print -e -u)"
}

function auth_aws () {
  ZONE="${1}"
  ZONE_FILE="${2}"
  VAULT_ADDR="https://$(jq -r --arg ZONE "${ZONE}" '. as $nodes|.[$ZONE]|"vault.\(.infra_zone_name).\($nodes[.infra_zone_name].domain_name)"' < "${ZONE_FILE}")"
  AWS_DEFAULT_REGION=$(jq -r --arg ZONE "${ZONE}" '.[$ZONE].provider.region' < "${ZONE_FILE}")
  export VAULT_ADDR AWS_DEFAULT_REGION
  # shellcheck disable=SC2046
  eval $(vault read "aws/sts/operator_${ZONE}" -format=json| jq -r '.data|"export AWS_ACCESS_KEY_ID=\(.access_key)\nexport AWS_SECRET_ACCESS_KEY=\(.secret_key)\nexport AWS_SESSION_TOKEN=\(.security_token)"')
}

function get_provider() {
  ZONE="${1}"
  ZONE_FILE="${2}"
  jq -r --arg ZONE "${ZONE}" '.[$ZONE].provider.type' < "${ZONE_FILE}"
}

function get_full_id() {
  kubectl get nodes "${1}" -o=jsonpath='{.spec.providerID}'
}

function get_instance_id_aws() {
  echo "${1}"| cut -d '/' -f5
}

function get_instance_id_fe() {
  echo "${1}"
}

#Main
if [ "${#}" -eq 1 ] && [ "${1}" = "-h" ]; then _help; exit 0; fi
if [ "${#}" -ne 2 ]; then _help; exit 1; fi
if [ "${1}" = "-h" ] || [ "${2}" = "-h" ]; then _help; exit 0; fi

ZONE=${1}
NODE=${2}
ZONE_FILE=$(mktemp)

sd get zones 2>/dev/null > "${ZONE_FILE}"
PROVIDER=$(get_provider "${ZONE}" "${ZONE_FILE}")
kswitch "${ZONE}"
FULL_ID=$(get_full_id "${NODE}")
INSTANCE_ID=$(get_instance_id_"${PROVIDER}" "${FULL_ID}")
"auth_${PROVIDER}" "${ZONE}" "${ZONE_FILE}"
echo "Delete server ${INSTANCE_ID}? (y/n)" >&2
read -r CONFIRM
if [[ "${CONFIRM}" == "y" ]]; then
  echo "Deleting ${INSTANCE_ID}"
  "delete_${PROVIDER}" "${INSTANCE_ID}"
fi
