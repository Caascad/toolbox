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

print_array_in_one_line() {
  k="$1"
  a="$2"
  printf "%-40s : %s\n" "$k" "$(echo "${a}" | jq -r '. |@csv')"
}

print_array() {
  k="$1"
  a="$2"
  sep=":"

  while read -r l; do
    printf "%-40s %1s %s\n" "$k" "$sep" "$l"
    k=""
    sep=""
  done <<<"$(echo "${a}" | jq -r '.[]')"
}

print_dict() {
  k="$1"
  v="$2"

  while read -r l; do
    eval "${l}"
    echo ""
  done <<<"$(echo "${v}" | jq -r --arg title "${k}" '. | to_entries | .[]| ["printf", "%-40s : %s", $title+"("+.key+")", .value]|@sh')"
}

get_zones_cluster() {
  echo "${ALLZONES}" | jq -r --arg c "${CLIENT}" '
      .[]
      | select(.type == "cluster")
      | select(.name == $c)
  '
}

get_zones_service() {
  subtype="$1"
  echo "${ALLZONES}" | jq -r --arg c "${CLIENT}" --arg s "${subtype}" '
      [.[]
      | select(.contract_zone_name == "obs-"+$c)
      | select(.subtype == $s)
      ]
  '
}

get_zone_service() {
  get_zones_service "$1" | jq '.[]'
}

print_grafana() {
  z=$(get_zone_service "grafana")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  dns_domain=$(echo "$z" | jq -r '.dns_domain')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  mapfile -t thanos_query_connected_services < <(echo "$z" | jq -r '.parameters.thanos_query_connected_services[].name' | sed -e 's/svc-monitoring-stack-client-\([a-z]*\)/\1/')

  print_header "Grafana"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_dict "Namespace" '{"main": "grafana-client-obs-'"${CLIENT}"'", "dashboards": "grafana-dashboards-obs-'"${CLIENT}"'"}'
  print_kv "Grafana URL" "https://grafana.${dns_domain}"
  print_kv "Grafana DS Thanos" "$(printf ",%s" "${thanos_query_connected_services[@]}" | sed -e 's/^,//g')"
}

print_grafana_client() {
  z=$(get_zone_service "grafana-client")
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  dns_domain=$(echo "$z" | jq -r '.dns_domain')
  cluster_name=$(echo "$z" | jq -r '.cluster_zone_name')
  mapfile -t thanos_query_connected_services < <(echo "$z" | jq -r '.parameters.thanos_query_connected_services[].name' | sed -e 's/svc-monitoring-stack-client-\([a-z]*\)/\1/')

  print_header "Grafana"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_dict "Namespace" '{"main": "grafana-client-obs-'"${CLIENT}"'", "dashboards": "grafana-dashboards-obs-'"${CLIENT}"'"}'
  print_kv "Grafana URL" "https://grafana.${dns_domain}"
  print_kv "Grafana DS Thanos" "$(printf ",%s" "${thanos_query_connected_services[@]}" | sed -e 's/^,//g')"
}

print_monitoring_stack() {
  ## IMPORTANT : this is duplicate code with print_monitoring_stack_corp().
  ## This function will be removed soon. This explains why we keep the code duplicated.
  replica=$(get_zones_service "monitoring-stack")
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
    svc_hint=$(echo "$z" | jq -r '.parameters["monitoring-stack"].svc_hint')

    print_header "Monitoring stack"
    print_kv "name" "${zone_name}"
    print_kv "Cluster" "${cluster_name}"
    print_kv "Namespace" "${namespace}"
    print_kv "Service Hint" "${svc_hint}"
    print_kv "Alertmanager notifications targets" "${notifications_targets}"
    print_kv "Retentions (raw / 5m / 1h)" "${retention_raw} / ${retention_5m} / ${retention_1h}"
  done
}

print_monitoring_stack_corp() {
  ## IMPORTANT : this is duplicate code with print_monitoring_stack().
  ## Code of print_monitoring_stack() will be removed soon. This explains why we keep the code duplicated.
  replica=$(get_zones_service "monitoring-stack-corp")
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
    svc_hint=$(echo "$z" | jq -r '.parameters["monitoring-stack"].svc_hint')

    print_header "Monitoring stack corp"
    print_kv "name" "${zone_name}"
    print_kv "Cluster" "${cluster_name}"
    print_kv "Namespace" "${namespace}"
    print_kv "Service Hint" "${svc_hint}"
    print_kv "Alertmanager notifications targets" "${notifications_targets}"
    print_kv "Retentions (raw / 5m / 1h)" "${retention_raw} / ${retention_5m} / ${retention_1h}"
  done
}

print_monitoring_stack_client() {
  z=$(get_zone_service "monitoring-stack-client")
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
  expose_prometheus_federate=$(echo "$z" | jq -r '.parameters["monitoring-stack"].prometheus.expose_prometheus_federate')

  print_header "Monitoring stack"
  print_kv "name" "${zone_name}"
  print_kv "Cluster" "${cluster_name}"
  print_dict "Namespace" '{"main": "'"${namespace}"'", "probes": "probes-obs-'"${CLIENT}"'", "rules": "rules-obs-'"${CLIENT}"'"}'
  print_kv "Alertmanager notifications targets" "${notifications_targets}"

  print_dict "NB Exporters" "${exporters_nb}"
  print_kv "Retentions (raw / 5m / 1h)" "${retention_raw} / ${retention_5m} / ${retention_1h}"
  print_kv "Prometheus exposes federate" "${expose_prometheus_federate}"
}

print_loki() {
  z=$(get_zone_service "loki")
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
  z=$(get_zone_service "loki-client")
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

print_kub_infos() {
  z=$(get_zones_cluster)
  [ -z "$z" ] && return
  zone_name=$(echo "$z" | jq -r '.name')
  client_zones=$(echo "$z" | jq -r '.child_zone_names')
  contract_zones_names=$(echo "${ALLZONES}" | jq -r --arg c "${CLIENT}" '
    . as $all
    | .[]
    | select(.type == "cluster")
    | select(.name == $c)
    | .child_zone_names as $svc
    
    | [ 
        $all 
	| to_entries 
	| .[]
	| select(.key as $k | $svc | index($k))
	| .value.contract_zone_name 
      ]
    | unique
    ')

  print_header "Cluster"
  print_kv "name" "${zone_name}"
  print_array "Contract zones" "${contract_zones_names}"
  print_array "Service zones" "${client_zones}"
}

print_grafana_client
print_monitoring_stack_client
print_loki_client
print_grafana
print_monitoring_stack
print_monitoring_stack_corp
print_loki
print_kub_infos
