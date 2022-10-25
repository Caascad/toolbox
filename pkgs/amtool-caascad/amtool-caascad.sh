#!/usr/bin/env bash

# Version : AMTOOL_CAASCAD_VERSION

# Usage:
# amtool-caascad <same options as in amtool> --alertmanager.url=<see below>
#
# where --alertmanager.url is one of :
# - https://<full URL>
# - <zone>/<subzone> (<zone> from caascad-zones; <subzone> as "caascad", "client", "app" or "consumption")
#

AMTOOL=amtool

CAASCAD_ZONES_URL=${CAASCAD_ZONES_URL:-https://git.corp.caascad.com/caascad/caascad-zones/raw/master/zones_short.json}
CONFIG_DIR="$HOME/.config/amtool-caascad"
CACHE_DIR="${CONFIG_DIR}/cache"
CAASCAD_ZONES_FILE="${CACHE_DIR}/zones.json"
CACHE_TIMEOUT="${CACHE_TIMEOUT:-10}"

HTTP_CONFIG_FILE_DIR="${CACHE_DIR}"

AMTOOL_CAASCAD_DEBUG=0

show_help() {
    cat <<EOHELP
amtool-wrapper help

This is a wrapper for amtool. Here are the specific options for the wrapper :

  --alertmanager.url : Also accepts "<zone>/<subzone>" format, where <subzone> is the "cc_prom" value as "infra-caascad",
                       "cloud-caascad", "cloud-client", "cloud-app" or "infra-consumption". The prefix can be ignored and
                       the value can also be "caascad", "client", "app" or "consumption".
                       When a regular URI is specified, it will be used as is.

  --http.config.file : HTTP configuration file as needed by amtool.
                       However, when it is not specified, and when --alertmanager.url="<zone>/<subzone>", it will
                       be generated.
                       When it is explicitely specified, it will override the generated one.
                       This can be useful when using the same token across multiple calls to Amtool.

  --force-refresh    : Force cache refresh
  --help             : Show this help before amtool help.
  --version          : Show the version of the wrapper before amtool version

EOHELP
}

log_debug() {
    if [ $AMTOOL_CAASCAD_DEBUG -eq 1 ]; then
        echo -e "\x1B[34m--- $*\x1B[0m" >&2
    fi
}

log-error() {
    echo -e "\x1B[31m--- $*\x1B[0m" >&2
}


setup() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    mkdir -p "${CACHE_DIR}"
    mkdir -p "${lockPath}"
}

check_cache_timeout() {
    # Check whether CACHE_TIMEOUT is an integer
    [ "${CACHE_TIMEOUT}" -eq "${CACHE_TIMEOUT}" ] 2>/dev/null && return
    log-error "CACHE_TIMEOUT has to be an integer !" && exit 1
}

_check_refresh_zones() {
    local lastUpdate
    local cacheTimeoutEpoch
    local nowEpoch
    lastUpdate="$(date --iso-8601=seconds -r "${CAASCAD_ZONES_FILE}" 2>/dev/null)" || return 1
    cacheTimeoutEpoch="$(date --date="${lastUpdate} +${CACHE_TIMEOUT} minutes" +"%s")" || return 1
    nowEpoch="$(date +"%s")"
    if [ "${nowEpoch}" -lt "${cacheTimeoutEpoch}" ]; then
        return 0
    fi
    return 1
}

refresh_zones_or_cache() {
    while true; do
        if [ "${forceRefresh}" -eq 0 ]; then
            _check_refresh_zones && log_debug "Not refreshing caascad-zones: cache is still valid" && return
        fi

        local lockName
        lockName="caascad_zones"
        lock_or_abort "${lockName}" || continue
        # Verifying if cached credentials are invalid
        [ "${forceRefresh}" -eq 0 ] && _check_refresh_zones && unlock "${lockName}" && continue
        # Writing new cached credentials
        refresh_zones || { [ -f "${CAASCAD_ZONES_FILE}" ] && log "Refreshing caascad-zones cache with old data" && touch "${CAASCAD_ZONES_FILE}"; }
        unlock "${lockName}"
        return
    done
}

refresh_zones() {
    log_debug "Refreshing caascad-zones..."
    local httpCode
    httpCode="$(curl -w "%{response_code}" --connect-timeout 2 -s -o "${CAASCAD_ZONES_FILE}.tmp" "${CAASCAD_ZONES_URL}")"
    [ "${httpCode}" != "200" ] && {
        log-error "Refreshing caascad-zones failed!"
        return 1
    }
    mv "${CAASCAD_ZONES_FILE}.tmp" "${CAASCAD_ZONES_FILE}" || {
        log-error "Unable to write ${CAASCAD_ZONES_FILE}"
        return 1
    }
}

init_lock_counter() {
    if [ "${initLockCounterRun:=0}" -eq 0 ]; then
        declare -g -A LOCKS
        trap unlock_all EXIT
        initLockCounterRun=1
        log_debug "Initializing lock counter"
    fi
}

unlock_all() {
    if [[ -v LOCKS[@] ]]; then
        log_debug "Cleaning remaining locks before exiting"
        for lock in "${!LOCKS[@]}"; do
            unlock "${lock}"
        done
    fi
}

wait_lock() {
    init_lock_counter
    local lock
    lock="${lockPath}/$*.lock"
    log_debug "Waiting for lock: ${lock}"
    while ! mkdir "${lock}" 2>/dev/null; do :; done
    LOCKS["$*"]=1
    log_debug "Lock acquired: ${lock}"
}

lock_or_abort() {
    init_lock_counter
    local lock
    lock="${lockPath}/$*.lock"
    log_debug "Trying to acquire lock: ${lock}"
    mkdir "${lock}" 2>/dev/null &&
        LOCKS["$*"]=1 &&
        log_debug "Lock acquired: ${lock}" &&
        return 0
    log_debug "Lock unavailable: ${lock}" && return 1
}

unlock() {
    local lock
    lock="${lockPath}/$*.lock"
    rm -r "${lock}" 2>/dev/null &&
        unset 'LOCKS["$*"]' &&
        log_debug "Lock released: ${lock}" &&
        return 0
    log_debug "Cannot release lock: ${lock}" && return 1
}

zone_attr() {
    zone=$1
    attr=$2
    jq -r ".[\"$zone\"].$attr" <"${CAASCAD_ZONES_FILE}"
}

parse_url() {
    ZONE=""
    GIVEN_SUBZONE=""
    SUBZONE=""

    # Check the format of $1
    case "$1" in
        http*)
            ;;
        */*)
            ZONE=$(echo "$url" | cut -d/ -f 1)
            GIVEN_SUBZONE=$(echo "$url" | cut -d/ -f 2)
            SUBZONE="${GIVEN_SUBZONE//*-/}"
            ;;
        *)
            echo "Wrong url format" 1>&2
            exit 1
    esac
}

build_url() {
    url="$1"
    namespace=""
    if [ "${SUBZONE}" = "caascad" ]; then
        namespace="monitoring"
        service="caascad-alertmanager"
    elif [ "${SUBZONE}" = "client" ]; then
        namespace="monitoring-client"
        service="client-alertmanager"
    elif [ "${SUBZONE}" = "app" ]; then
        namespace="monitoring-app"
        service="app-alertmanager"
    elif [ "${SUBZONE}" = "consumption" ]; then
        namespace="monitoring-consumption"
        service="consumption-alertmanager"
    else
        echo "In <zone>/<subzone>, subzone should be one of 'caascad', 'client', 'app' or 'consumption' (with a possible prefix as 'infra-' or 'cloud-'. Got '${GIVEN_SUBZONE}'" 1>&2
        exit 1
    fi

    domain_name=$(zone_attr "${ZONE}" "domain_name")

    url="--alertmanager.url=https://rancher.${ZONE}.${domain_name}/k8s/clusters/local/api/v1/namespaces/${namespace}/services/${service}:9093/proxy"
    echo "$url"
}

build_httpconfig() {
    # Check if httpconfig file exists
    http_config_file_path="$1"
    if [ -e "${http_config_file_path}" ]; then
        if [ "${forceRefresh}" -eq 0 ]; then
            return
        fi
    fi

    # Connect to vault
    domain_name=$(zone_attr "${ZONE}" "domain_name")
    export VAULT_ADDR="https://vault.${ZONE}.${domain_name}"
    vault token lookup >/dev/null 2>&1 || vault login -method oidc

    # Get the token
    token=$(vault read -field=token "secret/concourse-infra/global/kubernetes-${ZONE}")

    # Create the httpconfig file dir if it does not exists yet
    mkdir -p "$(dirname "${http_config_file_path}")"

    # Fill the file with the authorization (including the token)
    cat <<EOF > "$http_config_file_path"
authorization:
  type: Bearer
  credentials: $token
EOF
}

#### MAIN ####

ALL_ARGS=()
HTTP_CONFIG_FILE=""
http_config_file_needed="false"
display_help="false"
forceRefresh=0

{ [ -d /dev/shm ] && lockPath="/dev/shm"; } || lockPath="/tmp"
lockPath="${lockPath}/amtool_caascad.d"

setup
check_cache_timeout
refresh_zones_or_cache

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            echo "amtool-caascad wrapper version : AMTOOL_CAASCAD_VERSION"
            ${AMTOOL} --version
            exit 0
            ;;
        --http.config.file*)
            if [ "$1" = "--http.config.file" ]; then
                shift # next argument
                # --http.config.file will be removed with the above shift.
                # So we need to re-add it this way : --http.config.file=xxxx
                HTTP_CONFIG_FILE="--http.config.file=${1}"
            else
                HTTP_CONFIG_FILE="${1}"
            fi
            ;;
        --help)
            display_help="true"
            ALL_ARGS+=("$1")
            ;;
        --alertmanager.url*)
            if [ "$1" = "--alertmanager.url" ]; then
                shift # next argument
                url="${1}"
            else
                url=${1//--alertmanager.url=/}
            fi
            parse_url "$url"
            if [ ! "${ZONE}/${SUBZONE}" = "/" ]; then
                url=$(build_url "$url")
                http_config_file_needed="true"
            fi
            ALL_ARGS+=( "$url" )
            ;;
        --force-refresh)
            forceRefresh=1
            shift
            ;;
        *)
            ALL_ARGS+=("$1")
            ;;
    esac
    shift # next argument
done

if [ -z "${HTTP_CONFIG_FILE}" ] && [ "${http_config_file_needed}" = "true" ]; then
    http_config_file_path="${HTTP_CONFIG_FILE_DIR}/${ZONE}__${SUBZONE}"
    build_httpconfig "${http_config_file_path}"

    HTTP_CONFIG_FILE="--http.config.file=${http_config_file_path}"
fi
if [ -n "${HTTP_CONFIG_FILE}" ]; then
    ALL_ARGS+=("$HTTP_CONFIG_FILE")
fi
if [ "${display_help}" = "true" ]; then
  show_help
fi
"${AMTOOL}" "${ALL_ARGS[@]}"
