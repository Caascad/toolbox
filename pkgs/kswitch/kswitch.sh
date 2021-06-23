#!/usr/bin/env bash
# shellcheck disable=SC2086

set -eu
set -o pipefail

CAASCAD_ZONES_URL=${CAASCAD_ZONES_URL:-https://git.corp.cloudwatt.com/caascad/caascad-zones/raw/master/zones.json}
CONFIG_DIR="$HOME/.config/kswitch"
CACHE_DIR="${CONFIG_DIR}/cache"
CAASCAD_ZONES_FILE="${CACHE_DIR}/zones.json"
KSWITCH_DEBUG="${KSWITCH_DEBUG:-0}"
KSWITCH_TRACE="${KSWITCH_TRACE:-0}"
CACHE_TIMEOUT="${CACHE_TIMEOUT:-10}"
VAULT_CLIENT_TIMEOUT="${VAULT_CLIENT_TIMEOUT:-2}"

if [ $KSWITCH_TRACE -eq 1 ]; then set -x; fi

VAULT_FORMAT=json
export VAULT_FORMAT

log() {
  echo -e "\x1B[32m--- $*\x1B[0m" >&2
}

log_debug() {
  if [ $KSWITCH_DEBUG -eq 1 ]; then
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
  [ $disableInput -eq 1 ] && return
  read -p "Continue [y/n]: " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
}

wait_lock() {
    local lock
    lock="${lockPath}/$*.lock"
    log_debug "Waiting for lock: ${lock}"
    while ! mkdir "${lock}" 2>/dev/null; do :;done
    log_debug "Lock acquired: ${lock}"
}

lock_or_abort() {
    local lock
    lock="${lockPath}/$*.lock"
    log_debug "Trying to acquire lock: ${lock}"
    mkdir "${lock}" 2>/dev/null && log_debug "Lock acquired: ${lock}" && return 0
    log_debug "Lock unavailable: ${lock}" && return 1
}

unlock() {
    local lock
    lock="${lockPath}/$*.lock"
    rm -r "${lock}" 2>/dev/null && log_debug "Lock released: ${lock}" && return 0
    log_debug "Cannot release lock: ${lock}" && return 1
}

bash_completions() {
  cat <<EOF
_kswitch_completions() {
  local curr_arg;
  curr_arg=\${COMP_WORDS[COMP_CWORD]}
  if [ \${#COMP_WORDS[@]} -ge 3 ]; then
    return
  fi
  COMPREPLY=( \$(compgen -W "- \$(kubectl config get-contexts --output='name')" -- \$curr_arg ) );
}
complete -F _kswitch_completions kswitch
EOF
}

usage() {
  cat <<EOF
Usage:
  kswitch [--no-input] [--force-refresh] ZONE_NAME          Start tunnel to ZONE_NAME and change kubectl context
  kswitch [--json]                                          Show kswitch status
  kswitch -k, --kill                                        Stop any active tunnel
  kswitch -h, --help                                        This help
  kswitch --clean-cache                                     Remove cached files
  kswitch --force-unlock                                    Remove lock files
  kswitch -v, --version                                     Current kswitch version
  
Options:
  --no-input       Don't ask for user inputs
  --force-refresh  Force cache refresh

kswitch automatically setup an SSH tunnel to the specified zone K8S cluster.

To do this it will configure the local kubectl configuration (usually ~/.kube/config)
by adding the zone as a context and the user credentials by downloading them
from the .kube/config file of the bastion of the zone.

If the zone has not been configured with kswitch only the kubectl context is
changed.

You can get bash completions for kswitch, add this to your ~/.bashrc:

  source <(kswitch bash-completions)

Starship (https://starship.rs) example configuration:

    [custom.kswitch]
    command = """ kswitch --json | jq -e -r '. | select(.tunnel.status == "up") | select(.context == .tunnel.zone) | .context' """
    when    = "pgrep -f kswitch"
    symbol  = " "
    style   = "bold white"
    format  = "[\$symbol\$output](\$style) "

This will display the icon '' when a tunnel is up and the current kubectl
context matches the tunnel bastion.

EOF
}

setup() {
  if [ ! -d "$CONFIG_DIR" ]; then
    log "Looks like you are running kswitch for the first-time!"
    log "I'm going to create $CONFIG_DIR for storing kswitch configurations."
    _continue
    mkdir -p "$CONFIG_DIR"
  fi
  mkdir -p "${CACHE_DIR}"
  mkdir -p "${lockPath}"

  hasTunnel=$(kubectl config view -o=json | jq '(.clusters // {}) | map(select(.name == "tunnel")) | length')
  if [ ! "$hasTunnel" == "1" ]; then
    log "I'm going to add a cluster named tunnel to the local kube configuration:"
    run_c "kubectl config set-cluster tunnel --server https://localhost:${localPort} --insecure-skip-tls-verify=true"
  fi
}

clean_cache() {
  log "Cleaning cache:"
  [ -d "${CACHE_DIR}" ] && run_c "rm -rf ${CACHE_DIR}"
  log "Cache cleaned"
}

force_unlock() {
  log "Cleaning Locks:"
  local locks
  [ -d "${lockPath}" ] && locks=$(find ${lockPath} -name '*.lock' -exec echo {} +) || locks=""
  [ -n "${locks}" ] && run_c "rm -r $locks"
  log "All locks cleaned"
}

kill_tunnel() {
  # Add unused argument foo to run the command
  # it's not used but cli parsing requires it
  # This will kill the active ssh tunnel if any
  ssh -S $socketPath -O exit foo 2>/dev/null || true
}

vault_login() {
    vault token lookup >/dev/null 2>&1 || vault login -method oidc || { log-error "Vault is unreachable"; return 1; }
}

configure_kubeconfig() {
    if ! kubectl config get-contexts "${zone}" >/dev/null 2>&1; then
        log "No configuration has been found for zone ${zone}"
        log "Configuring kube credentials for zone ${zone}..."
        if [[ "$zone" =~ ^infra-* ]]; then
            vault_login
            kubeconfig=$(mktemp)
            vault read "secret/zones/fe/${zone}/kubeconfig" > $kubeconfig
            jq -r '.data.clusters[].cluster.server' $kubeconfig | cut -d'/' -f3 > "${CONFIG_DIR}/${zone}"
            jq -r '.data.users[].user["client-certificate-data"]' $kubeconfig | base64 -d > "${CONFIG_DIR}/${zone}-cert"
            jq -r '.data.users[].user["client-key-data"]' $kubeconfig | base64 -d > "${CONFIG_DIR}/${zone}-key"
            run "kubectl config set-credentials $zone-admin --client-certificate=${CONFIG_DIR}/${zone}-cert --client-key=${CONFIG_DIR}/${zone}-key"
            rm -f ${kubeconfig}
        elif [[ "$zoneType" =~ fe|azure ]]; then
            run "kubectl config set-credentials $zone-admin --exec-api-version=client.authentication.k8s.io/v1beta1 --exec-command=kswitch --exec-arg=-c --exec-arg=${zone}"
        elif [ "$zoneType" == "aws" ]; then
            run "kubectl config set-credentials $zone-admin --exec-api-version=client.authentication.k8s.io/v1alpha1 --exec-command=kswitch --exec-arg=-c --exec-arg=${zone}"
        else
            log-error "Zone provider $zoneType not supported."
            exit 1
        fi
        log "Configuring kube context for zone ${zone}..."
        run "kubectl config set-context $zone --user=${zone}-admin --cluster=tunnel"
    fi
}

start_tunnel() {
    dest=cloud@bst.${zone}.caascad.com

    if [[ "$zone" =~ ^infra-* ]]; then
        kubeServer=$(cat "${CONFIG_DIR}/${zone}")
    elif [ "$zoneType" == "fe" ]; then
        vault_login
        kubeServer=$(vault read "secret/zones/fe/${zone}/kubeconfig" | jq -r .data.clusters[].cluster.server | cut -d'/' -f3)
    elif [ "$zoneType" == "aws" ]; then
        vault_login
        kubeServer="$(vault read "secret/zones/aws/${zone}/eks" | jq -r .data.endpoint | cut -d'/' -f3):443"
    elif [ "$zoneType" == "azure" ]; then
        vault_login
        kubeServer="$(vault read "secret/zones/azure/${zone}/kubeconfig" | jq -r .data.host | cut -d'/' -f3)"
    fi

    log "Forwarding through ${dest}..."
    ssh -4 -M -S $socketPath -fnNT -L ${localPort}:${kubeServer} -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 $dest
}

get_aws_credentials() {
    # if creds are newer that 9h no need to ask for new credentials
    if find "$CONFIG_DIR" -mmin -$((60*9)) -name "${awsCredsFile}" | grep -q .; then
        return
    fi
    log_debug "Get AWS credentials..."
    vault write aws/sts/${awsSTSRoleName} ttl=10h | \
        jq -r '.data | "export AWS_ACCESS_KEY_ID=\(.access_key); export AWS_SECRET_ACCESS_KEY=\(.secret_key); export AWS_SESSION_TOKEN=\(.security_token)"' > "${awsCredsFilePath}"
}

check_cache_timeout(){
    # Check whether CACHE_TIMEOUT is an integer
    [ "${CACHE_TIMEOUT}" -eq "${CACHE_TIMEOUT}" ] 2>/dev/null && return
    log-error "CACHE_TIMEOUT has to be an integer !" && exit 1
}

_check_cached_credentials(){
    local cachedResponse
    local cacheTimeout
    local cacheTimeoutEpoch
    local nowEpoch
    cachedResponse="$(cat "${cachedExecCredentialsPath}" 2>/dev/null)" || return 1
    cachedResponse="${cachedResponse:-"{}"}"
    cacheTimeout="$(jq -e -r '.cacheTimeout' <<<"${cachedResponse}")" || return 1
    cacheTimeoutEpoch="$(date --date="${cacheTimeout}" +"%s")" ||  return 1
    nowEpoch="$(date +"%s")"
    if [ "${nowEpoch}"  -lt "${cacheTimeoutEpoch}" ]; then
        jq -e -r '.execCredential' <<<"${cachedResponse}"
        return 0
    fi
    return 1
}

get_credentials_or_cache() {
    local toRefresh
    toRefresh=${forceRefresh}
    while true; do
        if [ "${toRefresh}" -eq 0 ]; then
            local cachedCredentials
            cachedCredentials=$(_check_cached_credentials) && log_debug "Fetching credentials from cache" && echo "${cachedCredentials}" && return
        fi

        local lockName
        lockName="credentials_${zone}"
        lock_or_abort "${lockName}" || continue
        # Verifying if cached credentials are invalid
        [ "${toRefresh}" -eq 0 ] && _check_cached_credentials && unlock "${lockName}" && continue
        # Writing new cached credentials
        defaultCacheTimeout="$(date --date="+${CACHE_TIMEOUT} minutes" --iso-8601=seconds)"
        log_debug "Updating cached credentials"
        local exit_code
        { get_credentials | jq -e -r --arg defaultCacheTimeout "${defaultCacheTimeout}" '{"cacheTimeout": (.status.expirationTimestamp // $defaultCacheTimeout), "execCredential": . }' > "${cachedExecCredentialsPath}.tmp"; } && exit_code=0 || exit_code="$?"
        [ "${exit_code}" -ne 0 ] && log-error "Cannot refresh credentials" && unlock ${lockName} && exit 1
        mv "${cachedExecCredentialsPath}.tmp" "${cachedExecCredentialsPath}" || { log-error "Unable to write ${cachedExecCredentialsPath}" && unlock ${lockName} && exit 1; }
        toRefresh=0
        unlock "${lockName}"
    done
}

get_credentials() {
    vault_login || return 1
    if [ "$zoneType" == "fe" ]; then
        log_debug "Get FE k8s certificates..."
        vault read "secret/zones/fe/${zone}/kubeconfig" | \
            jq '{"apiVersion": "client.authentication.k8s.io/v1beta1", "kind": "ExecCredential", "status": { "clientCertificateData": .data.users[].user["client-certificate-data"] | @base64d, "clientKeyData": .data.users[].user["client-key-data"] | @base64d }}' || return 1
    elif [ "$zoneType" == "aws" ]; then
        get_aws_credentials
        # shellcheck disable=SC1090,SC2015
        source "${awsCredsFilePath}"
        log_debug "Get AWS K8S token..."
        eval "$(vault read "secret/zones/aws/${zone}/eks" | \
            jq -e -r '.data | "aws --region \(.region) eks get-token --cluster-name \(.name)"')" || return 1
    elif [ "$zoneType" == "azure" ]; then
        log_debug "Get Azure k8s certificates..."
        vault read "secret/zones/azure/${zone}/kubeconfig" | \
            jq -e '{"apiVersion": "client.authentication.k8s.io/v1beta1", "kind": "ExecCredential", "status": { "clientCertificateData": .data.client_certificate | @base64d, "clientKeyData": .data.client_key | @base64d }}' || return 1
    else
        log-error "Zone provider $zoneType not supported."
        return 1
    fi
}

_check_refresh_zones(){
    local lastUpdate
    local cacheTimeoutEpoch
    local nowEpoch
    lastUpdate="$(date --iso-8601=seconds -r "${CAASCAD_ZONES_FILE}" 2>/dev/null)" || return 1
    cacheTimeoutEpoch="$(date --date="${lastUpdate} +${CACHE_TIMEOUT} minutes" +"%s")" || return 1
    nowEpoch="$(date +"%s")"
    if [ "${nowEpoch}"  -lt "${cacheTimeoutEpoch}" ]; then
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
        refresh_zones || { [ -f "${CAASCAD_ZONES_FILE}" ] && log "Refreshing caascad-zones cache with old data"  && touch "${CAASCAD_ZONES_FILE}"; }
        unlock "${lockName}"
        return
    done
}

refresh_zones() {
    log_debug "Refreshing caascad-zones..."
    local httpCode
    httpCode="$(curl -w "%{response_code}" --connect-timeout 2 -s -o "${CAASCAD_ZONES_FILE}.tmp" "${CAASCAD_ZONES_URL}")" || { [ "${httpCode}" != "200" ] && log-error "Refreshing caascad-zones failed!" && return 1; }
    mv "${CAASCAD_ZONES_FILE}.tmp" "${CAASCAD_ZONES_FILE}" || { log-error "Unable to write ${CAASCAD_ZONES_FILE}" && return 1; }
}

zone_exists() {
    zone=$1
    [ -f "${CAASCAD_ZONES_FILE}" ] || return 1
    jq -e ".[\"${zone}\"]?" < "${CAASCAD_ZONES_FILE}" >/dev/null
}

zone_attr() {
    zone=$1
    attr=$2
    jq -r ".[\"$zone\"].$attr" < "${CAASCAD_ZONES_FILE}"
}

status() {
  context=$(kubectl config current-context)
  tunnelStatus="down"
  tunnelPID=-1
  tunnelBastion=""
  tunnelZone=""

  if [ -S $socketPath ]; then
    tunnelPID=$(ssh -S $socketPath -O check foo 2>&1 | sed 's/.*pid=\([0-9]*\).*/\1/')
    tunnelBastion=$(tr '\000' ':' </proc/${tunnelPID}/cmdline | rev | cut -d: -f2 | rev)
    tunnelZone=$(echo $tunnelBastion | cut -d. -f2)
    tunnelStatus="up"
  fi

  if [ $jsonOutput -eq 1 ]; then
    cat <<EOF
{
    "context": "${context}",
    "tunnel": {
        "status": "${tunnelStatus}",
        "pid": ${tunnelPID},
        "bastion": "${tunnelBastion}",
        "zone": "${tunnelZone}"
    }
}
EOF
    [ "$tunnelStatus" = "down" ] && exit 1
  else
    log "Current context is $context"
    if [ "$tunnelStatus" = "down" ]; then
      log-error "Tunnel is down: run kswitch $context"
      exit 1
    fi
    log "Tunnel is active (pid=$tunnelPID)"
    log "Tunneling through ${tunnelBastion}"
  fi

  exit 0
}

jsonOutput=0
localPort=30000
socketPath="/dev/shm/kswitch"
[ ! -d /dev/shm ] && socketPath="/tmp/kswitch"
{ [ -d /dev/shm ] && lockPath="/dev/shm"; } || lockPath="/tmp"
lockPath="${lockPath}/kswitch.d"
zone=""
execCredentialMode=0
forceRefresh=0
disableInput=0
cleanCache=0
forceUnlock=0

while (( "$#" )); do
    case "$1" in
        bash-completions)
        bash_completions
        exit 0
        ;;
        -v|--version)
        echo 'KSWITCH_VERSION'
        exit 0
        ;;
        -h|--help)
        usage
        exit 0
        ;;
        -k|--kill)
        kill_tunnel
        exit 0
        ;;
        --json)
        jsonOutput=1
        shift
        ;;
        --force-refresh)
        forceRefresh=1
        shift
        ;;
        --clean-cache)
        cleanCache=1
        shift
        ;;
        --force-unlock)
        forceUnlock=1
        shift
        ;;
        -c)
        execCredentialMode=1
        shift
        ;;
        --no-input)
        disableInput=1
        shift
        ;;
        -*) # unsupported flags
        log-error "unsupported flag $1"
        usage
        exit 1
        ;;
        *)
        [ "$zone" != "" ] && (log-error "too much arguments" && usage && exit 1)
        zone=$1
        shift
        ;;
    esac
done


exitNow=0
[ "${cleanCache}" -eq 1 ] && clean_cache && exitNow=1
[ "${forceUnlock}" -eq 1 ] && force_unlock && exitNow=1
[ "${exitNow}" -eq 1 ] && exit 0

# Makes sure to use ~/.kube/config
unset KUBECONFIG

[ "$zone" == "" ] && status

setup
check_cache_timeout
refresh_zones_or_cache

if zone_exists "${zone}"; then
    log_debug "Found caascad zone ${zone}"
    infraZone=$(zone_attr $zone "infra_zone_name")
    domainName=$(zone_attr $infraZone "domain_name")
    zoneType=$(zone_attr $zone "provider.type")
    cachedExecCredentialsPath="${CACHE_DIR}/${zone}_kubectl_exec_credential"
    log_debug "Zone is on provider ${zoneType}"

    if [ "$zoneType" == "aws" ]; then
        awsSTSRoleName="operator_${zone}"
        awsCredsFile="${zone}_aws_credentials"
        awsCredsFilePath="${CONFIG_DIR}/${awsCredsFile}"
    fi

    VAULT_ADDR="https://vault.${infraZone}.${domainName}"
    export VAULT_ADDR
    export VAULT_CLIENT_TIMEOUT

    [ $execCredentialMode -eq 1 ] && { get_credentials_or_cache; exit 0; }

    kill_tunnel
    configure_kubeconfig
    start_tunnel
else
    [ $execCredentialMode -eq 1 ] && log "No caascad zone ${zone} found" && exit 1
    log "No caascad zone ${zone} found. Trying to switch context anyway..."
fi

kubectl config use-context $zone
