set -eu
set -o pipefail

log() {
  echo -e "\e[32m--- $*\e[0m" >&2
}

run() {
  echo -e "\e[33m+++ $1\e[0m" >&2
  eval $1
}

run_c() {
  echo -e "\e[33m+++ $1\e[0m" >&2
  _continue
  eval $1
}

_continue() {
  read -p "Continue [y/n]: " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
}

usage() {
  cat <<EOF
Usage: kswitch <zone_name>
EOF
}

localPort=30000
configDir=$HOME/.config/kswitch
zone=${1:-""}

# Makes sure to use ~/.kube/config
unset KUBECONFIG

[ "$zone" == "" ] && (echo "Missing zone" && usage && exit 1)

dest=cloud@bst.${zone}.caascad.com

if [ ! -d $configDir ]; then
  log "Looks like you are run_cning kswitch for the first-time!"
  log "I'm going to create $configDir for storing kswitch configurations."
  _continue
  mkdir -p $configDir
fi

if ! kubectl config get-clusters | grep -q tunnel; then
  log "I'm going to add a cluster named tunnel to the local kube configuration:"
  run_c "kubectl config set-cluster tunnel --server https://localhost:${localPort} --insecure-skip-tls-verify=true"
fi

if [ ! -f ${configDir}/${zone} ]; then
  log "No configuration has been found for zone ${zone}"
  log "Fetching kubeconfig on ${zone} bastion..."
  kubeconfig=$(mktemp)
  run "ssh -o ConnectTimeout=3 $dest cat .kube/config > $kubeconfig"
  jq -r .clusters[].cluster.server $kubeconfig | cut -d'/' -f3 > $configDir/$zone
  jq -r '.users[].user["client-certificate-data"]' $kubeconfig | base64 -d > ${configDir}/${zone}-cert
  jq -r '.users[].user["client-key-data"]' $kubeconfig | base64 -d > ${configDir}/${zone}-key
  chmod 600 ${configDir}/${zone}-key
  log "Configuring kube credentials for zone ${zone}..."
  run "kubectl config set-credentials $zone-admin --client-certificate=${configDir}/${zone}-cert --client-key=${configDir}/${zone}-key"
  log "Configuring kube context for zone ${zone}..."
  run "kubectl config set-context $zone --user=${zone}-admin --cluster=tunnel"
  rm -f $kubeconfig
  log "Configuration for ${zone} is completed!"
fi

kube=$(cat ${configDir}/${zone})

# Add unused argument foo to run the command
# it's not used but cli parsing requires it
# This will kill the active ssh tunnel if any
ssh -S /dev/shm/kswitch -O exit foo 2>/dev/null || true

log "Forwarding through ${dest}..."
ssh -M -S /dev/shm/kswitch -fnNT -L ${localPort}:${kube} -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 $dest

kubectl config use-context $zone
