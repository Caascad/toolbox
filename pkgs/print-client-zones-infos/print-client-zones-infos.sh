#! /bin/bash

CLIENT=$1

APP=print-client-zones-infos

if [ "${CLIENT}" = "" ]; then
    echo "Usage: $0 <client>"
    echo "Exemple : $0 demo"
    exit 1
fi

if [ "${CLIENT}" = "version" ] || [ "${CLIENT}" = "--version" ]; then
  echo "${APP} version : PRINT_CLIENT_ZONES_INFOS_VERSION"
  exit 0
fi

CAASCAD_ZONES_URL=${CAASCAD_ZONES_URL:-https://git.corp.caascad.com/caascad/terraform/envs-ng/-/raw/master/gen/zones_static/zones.json}

ALLZONES=$(curl -sL --connect-timeout 2 "${CAASCAD_ZONES_URL}" 2>/dev/null)

#CONTRACT below is unused. Leaving it here for the example.
#CONTRACT=$(echo "${ALLZONES}" | jq -r --arg c "${CLIENT}" '.["obs-"+$c]')

print_header() {
  header="$1"
  line="====================================================="
  printf "\n=== %s %s\n" "${header}" "${line:${#header}}"
}

print_kv() {
  k="$1"
  v="$2"
  printf "%-40s : %s\n" "$k" "$v"
}

print_dict() {
  k="$1"
  v="$2"

  while read -r l; do
    eval "${l}"
    echo ""
  done <<< "$(echo "${v}" | jq -r --arg title "${k}" '. | to_entries | .[]| ["printf", "%-40s : %s", $title+"("+.key+")", .value]|@sh')"
}

get_zones() {
  subtype="$1"
  echo "${ALLZONES}" | jq -r --arg c "${CLIENT}" --arg s "${subtype}" '
      [.[]
      | select(.contract_zone_name == "obs-"+$c)
      | select(.subtype == $s)
      ]
  '
}

get_zone() {
  get_zones "$1" | jq '.[]'
}

print_grafana() {
  z=$(get_zone "grafana")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  dns_domain=$(echo "$z" | jq -r '.dns_domain')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  mapfile -t thanos_query_connected_services < <(echo "$z" | jq -r '.parameters.thanos_query_connected_services[].name' |sed -e 's/svc-monitoring-stack-client-\([a-z]*\)/\1/')

  print_header "Grafana"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_dict "Namespace" '{"main": "grafana-client-obs-'"${CLIENT}"'", "dashboards": "grafana-dashboards-obs-'"${CLIENT}"'"}'
  print_kv "Grafana URL" "https://grafana.${dns_domain}"
  print_kv "Grafana DS Thanos" "$(printf ",%s" "${thanos_query_connected_services[@]}" | sed -e 's/^,//g')"
}

print_grafana_client() {
  z=$(get_zone "grafana-client")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  dns_domain=$(echo "$z" | jq -r '.dns_domain')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  mapfile -t thanos_query_connected_services < <(echo "$z" | jq -r '.parameters.thanos_query_connected_services[].name' |sed -e 's/svc-monitoring-stack-client-\([a-z]*\)/\1/')

  print_header "Grafana"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_dict "Namespace" '{"main": "grafana-client-obs-'"${CLIENT}"'", "dashboards": "grafana-dashboards-obs-'"${CLIENT}"'"}'
  print_kv "Grafana URL" "https://grafana.${dns_domain}"
  print_kv "Grafana DS Thanos" "$(printf ",%s" "${thanos_query_connected_services[@]}" | sed -e 's/^,//g')"
}

print_monitoring_stack() {
  replica=$(get_zones "monitoring-stack")
  [ "$replica" == "[]" ] && return
  for zname in $(echo "$replica" | jq -r '.[].name' | sort); do
    z="$(echo "${replica}" | jq -r --arg n "${zname}" '.[] | select(.name == $n)')"
    zone_name=$(echo "$z" | jq -r '.name')
    cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
    namespace=$(echo "$z" | jq -r '.parameters["monitoring-stack"].namespace')
    notifications_targets=$(echo "$z" | jq -r '[.parameters["monitoring-stack"].alertmanager.notifications_targets[].name]|@csv' | sed -e 's/"//g' -e 's/,/, /g')
    [ -z "${notifications_targets}" ] && notifications_targets="(aucune)"
    retention_raw=$(echo "$z" | jq -r '.parameters.thanos.retention.raw')
    retention_5m=$(echo "$z" | jq -r '.parameters.thanos.retention.downsampling_5m')
    retention_1h=$(echo "$z" | jq -r '.parameters.thanos.retention.downsampling_1h')

    print_header "Monitoring stack"
    print_kv "name" "${zone_name}"
    print_kv "Cluster" "${cluster_name}"
    print_kv "Namespace" "${namespace}"
    print_kv "Alertmanager notifications targets" "${notifications_targets}"
    print_kv "Retentions (raw / 5m / 1h)" "${retention_raw} / ${retention_5m} / ${retention_1h}"
  done
}

print_monitoring_stack_client() {
  z=$(get_zone "monitoring-stack-client")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  namespace=$(echo "$z" | jq -r '.parameters["monitoring-stack"].namespace')
  notifications_targets=$(echo "$z" | jq -r '[.parameters["monitoring-stack"].alertmanager.notifications_targets[].name]|@csv' | sed -e 's/"//g' -e 's/,/, /g')
  [ -z "${notifications_targets}" ] && notifications_targets="(aucune)"
  exporters_nb=$(echo "$z" | jq -r '.parameters["monitoring-stack"].prometheus.exporters | to_entries | map(.value = (.value | length)) | from_entries')
  retention_raw=$(echo "$z" | jq -r '.parameters.thanos.retention.raw')
  retention_5m=$(echo "$z" | jq -r '.parameters.thanos.retention.downsampling_5m')
  retention_1h=$(echo "$z" | jq -r '.parameters.thanos.retention.downsampling_1h')

  print_header "Monitoring stack"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_dict "Namespace" '{"main": "'"${namespace}"'", "probes": "probes-obs-'"${CLIENT}"'", "rules": "rules-obs-'"${CLIENT}"'"}'
  print_kv "Alertmanager notifications targets" "${notifications_targets}"

  print_dict "NB Exporters" "${exporters_nb}"
  print_kv "Retentions (raw / 5m / 1h)" "${retention_raw} / ${retention_5m} / ${retention_1h}"
}

print_loki() {
  z=$(get_zone "loki")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  retention=$(echo "$z" | jq -r '.parameters.loki.retention')

  print_header "Loki"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_kv "Namespace" "loki-client-obs-${CLIENT}"

  print_kv "Retention" "${retention}"
}

print_loki_client() {
  z=$(get_zone "loki-client")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  retention=$(echo "$z" | jq -r '.parameters.loki.retention')

  print_header "Loki"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_kv "Namespace" "loki-client-obs-${CLIENT}"

  print_kv "Retention" "${retention}"
}

print_grafana_client
print_monitoring_stack_client
print_loki_client
print_grafana
print_monitoring_stack
print_loki
