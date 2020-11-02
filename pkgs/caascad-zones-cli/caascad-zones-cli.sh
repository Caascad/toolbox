#!/usr/bin/env bash
# shellcheck disable=SC2086

set -eu
set -o pipefail

CAASCAD_ZONES_URL=${CAASCAD_ZONES_URL:-https://git.corp.cloudwatt.com/caascad/caascad-zones/raw/master/zones.json}
CONFIG_DIR="$HOME/.config/caascad-zones-cli"
CAASCAD_ZONES_FILE="$CONFIG_DIR/zones.json"
GETZONES_DEBUG=${GETZONES_DEBUG:-0}

log() {
  echo -e "\x1B[32m--- $*\x1B[0m" >&2
}

log_debug() {
  if [ $GETZONES_DEBUG -eq 1 ]; then
    echo -e "\x1B[34m--- $*\x1B[0m" >&2
  fi
}

log-error() {
  echo -e "\x1B[31m--- $*\x1B[0m" >&2
}

run() {
  echo -e "\x1B[33m+++ $1\x1B[0m" >&2
  eval "$1"
}

run_c() {
  echo -e "\x1B[33m+++ $1\x1B[0m" >&2
  _continue
  eval "$1"
}

_continue() {
  read -p "Continue [y/n]: " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
}

bash_completions() {
  cat <<EOF
_caascad-zones-cli_completions() {
  local curr_arg;
  curr_arg=\${COMP_WORDS[COMP_CWORD]}
  if [ \${#COMP_WORDS[@]} -ge 3 ]; then
    return
  fi
}
complete -F _caascad-zones-cli_completions caascad-zones-cli
EOF
}

usage() {
  cat <<EOF
Usage:
  caascad-zones-cli PARENT_ZONE_NAME     Get a zones list of OCB zones and client zones attached to an INFRA_ZONE_NAME
  caascad-zones-cli -h, --help           This help
  caascad-zones-cli -v, --version        Current caascad-zones-cli version

caascad-zones-cli automatically give a list of OCB and Client zones attached to an INFRA_ZONE_NAME.

To do this it will request the zones.json in of caascad zones

You can get bash completions for caascad-zones-cli, add this to your ~/.bashrc:

  source <(caascad-zones-cli bash-completions)

EOF
}

refresh_zones() {
    log_debug "Refreshing caascad-zones..."
    curl -s -o "${CAASCAD_ZONES_FILE}" "${CAASCAD_ZONES_URL}"
}

zone_exists() {
    zone=$1
    jq -e ".[\"${zone}\"]?" < "${CAASCAD_ZONES_FILE}" >/dev/null
}

zone_contains() {
    anItem="$1"
    shift
    aList=( "$@" )

    for item in "${aList[@]}"; do
      [ ${item} == "${anItem}" ] && return 0
    done

    return 1
}

zone_parent_zone_name() {
    zone=$1
    jq -r ".[] | select(.parent_zone_name == env.$zone) | .name" < "${CAASCAD_ZONES_FILE}"
}

zone_infra_zone_name() {
    zone=$1
    jq -r ".[] | select(.infra_zone_name == env.$zone) | select(.type == \"client\") | .name" < "${CAASCAD_ZONES_FILE}"
}

get_infra_zone_names() {
    jq -r ".[].infra_zone_name" < "${CAASCAD_ZONES_FILE}" | sort -u
}

infra_zone_names=( $(get_infra_zone_names) )

infra_zone_name=""

while (( "$#" )); do
  case "$1" in
    bash-completions)
    bash_completions
    exit 0
    ;;
    -v|--version)
    echo 'GETZONES_VERSION'
    exit 0
    ;;
    -h|--help)
    usage
    exit 0
    ;;
    -*) #unsupported flags
    log-error "unsupported flag $1"
    usage
    exit 1
    ;;
    *)
    [ "$infra_zone_name" != "" ] && (log-error "too much arguments" && usage && exit 1)
    infra_zone_name=$1
    shift
    ;;
  esac
done

refresh_zones

if zone_contains "$infra_zone_name" "${INFRA_ZONES_NAMES[@]}"; then
  log-debug "Found caascad infra zone name ${infra_zone_name}"
  ocbZonesList=$(zone_parent_zone_name "$infra_zone_name")
  echo "${ocbZonesList[@]}"
  log_debug "OCB Zones is for infra zone name ${infra_zone_name} are: [" "${ocbZonesList[@]}" "]."
  clientsZonesList=$(zone_infra_zone_name "$infra_zone_name")
  echo "${clientsZonesList[@]}"
  log_debug "Clients Zones is for infra zone name ${infra_zone_name} are: [" "${clientsZonesList[@]}" "]."
else
  log "${infra_zone_name} is not a valid infrazone name."
  exit 1
fi
