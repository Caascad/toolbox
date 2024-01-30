#!/usr/bin/env bash
set -euo pipefail

SD_DEBUG=${SD_DEBUG:-0}
SD_TRACE=${SD_TRACE:-0}
if [ "$SD_TRACE" -eq 1 ]; then set -x; fi

CAASCAD_ZONES_URL=https://git.corp.caascad.com/caascad/terraform/envs-ng/-/raw/master/gen/zones_static/zones.json
RUN_DIR="/run/user/$(id -u)/caascad-sd"
CAASCAD_ZONES_LOCAL="${RUN_DIR}/zones.json"

#main entry points
infra_zones () {
  pull_caascad_zone
}

get () {
  TYPE=$1
  case ${TYPE} in
    "zones")
      pull_caascad_zone
      cat "${CAASCAD_ZONES_LOCAL}"
      ;;
    "infra_zone_names")
      jq -r '.| to_entries[]| select(.value.type=="infra")| .key' < "${CAASCAD_ZONES_LOCAL}"
      ;;
  esac
  }

#helpers
_help () {
  cat <<EOF
NAME
      Helper script used to handle the easily retrieve zones information

SYNOPSIS
      sd get zones|infra_zone_names

DESCRIPTION
      get
            get zones

EXAMPLES

      $ sd get zones
EOF
  }

log_info () {
  echo -e "\x1B[32m--- $*\x1B[0m" >&2
  }

log_debug () {
  if [ "${SD_DEBUG}" -eq 1 ]; then
    echo -e "\x1B[34m--- $*\x1B[0m" >&2
  fi
  }

log_error () {
  echo -e "\x1B[31m--- $*\x1B[0m" >&2
  }

pull_caascad_zone () {
  curl -L -k -s -o "${CAASCAD_ZONES_LOCAL}" "${CAASCAD_ZONES_URL}"
  }

# display parameters
log_debug "debug level is: ${SD_DEBUG}"
log_debug "trace level is: ${SD_TRACE}"
log_debug "caascad zones url is: ${CAASCAD_ZONES_URL}"
log_debug "local caascad zones file is: ${CAASCAD_ZONES_LOCAL}"

# parameters parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    help | -h | --help)
      _help
      exit 0
      ;;
    get)
      shift
      if [ "$#" -eq "0" ]; then _help; exit 1; fi
      TYPE=$1
      if [[ "${TYPE}" != "zones" && "${TYPE}" != "infra_zone_names" ]]; then _help; exit 1; fi
      get "${TYPE}"
      exit 0
      ;;
    *)
      _help
      exit 1
      ;;
  esac
done

_help
