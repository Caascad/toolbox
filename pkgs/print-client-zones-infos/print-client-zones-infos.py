#!/usr/bin/env python3

from sys import argv, exit, stderr, stdout
import json
import urllib.request


def print_help(file=stdout):
    print("TODO: print help", file=file)


def print_version():
    print("TODO: print version")


def normalize(text):
    return text.replace("_", " ").replace("-", " ").title()


def header(text):
    return f"=== {(normalize(text) + ' ').rjust(1).ljust(54, '=')}"


def parameter(name, value):
    return f"{(normalize(name) + ':').ljust(40)} {value}"


def get_zones(
    zones_url="https://git.corp.caascad.com/caascad/terraform/envs-ng/-/raw/master/gen/zones_static/zones.json",
):
    with urllib.request.urlopen(zones_url) as zones:
        return json.load(zones)


def filter_services(zones, contract, subtypes):
    return (
        zone
        for zone in zones.values()
        if zone.get("contract_zone_name") == contract
        and zone.get("subtype") in subtypes
    )


def print_services(client, services):
    for zone_data in services:
        subtype = zone_data.get("subtype", "")
        if subtype.startswith("grafana"):
            view = grafana_service_view(client, subtype, zone_data)
        elif subtype.startswith("loki"):
            view = loki_service_view(subtype, zone_data)
        elif subtype.startswith("monitoring-stack"):
            view = monitoring_stack_service_view(client, subtype, zone_data)
        else:
            view = zone_data
        print_view(subtype, view)


def common_fields(subtype, zone_data):
    return {
        "name": zone_data.get("name", "<ERROR NO VALUE>"),
        "cluster": zone_data.get("cluster_zone_name", "<ERROR NO VALUE>"),
    }


def grafana_service_view(client, subtype, zone_data):
    if dns_domain := zone_data.get("dns_domain"):
        grafana_url = f"https://grafana.{dns_domain}"
    else:
        grafana_url = "<ERROR NO VALUE>"

    try:
        # TODO: thanos_query_connected_services peut être un dict (team01) OU une liste (corp-prd)
        # donc le .items()... ça dépend
        print(zone_data["parameters"]["thanos_query_connected_services"])
        thanos = [
            thanos_data.get("name", "<ERROR NO VALUE>").replace(
                "svc-monitoring-stack-client-", ""
            )
            for x, thanos_data in zone_data["parameters"][
                "thanos_query_connected_services"
            ].items()
        ]
    except KeyError:
        thanos = []

    return common_fields(subtype, zone_data) | {
        "Namespace (main)": f"grafana-client-obs-{client}",
        "Namespace (dashboards)": f"grafana-dashboards-obs-{client}",
        "Grafana_url": grafana_url,
        "Grafana DS Thanos": thanos,
    }


def loki_service_view(subtype, zone_data):
    if contract := zone_data.get("contract_zone_name"):
        namespace = f"loki-client-{contract}"
    else:
        namespace = "<ERROR NO VALUE>"

    try:
        retention = zone_data["parameters"]["loki"]["retention"]
    except KeyError:
        retention = ""

    return common_fields(subtype, zone_data) | {
        "namespace": namespace,
        "retention": retention,
    }


def monitoring_stack_service_view(client, subtype, zone_data):
    parameters = zone_data.get("parameters", {})
    monitoring_stack = parameters.get("monitoring-stack", {})
    thanos = parameters.get("thanos", {})

    namespace = monitoring_stack.get("namespace", "<ERROR NO VALUE>")

    alertmanager_notifications_targets = [
        target.get("name")
        for target in monitoring_stack.get("alertmanager", {}).get(
            "notifications_targets", []
        )
    ]
    if not alertmanager_notifications_targets:
        alertmanager_notifications_targets = None

    retentions = thanos.get("retention", {})
    retention_raw = retentions.get("raw")
    retention_5m = retentions.get("downsampling_5m")
    retention_1h = retentions.get("downsampling_1h")

    if subtype == "monitoring-stack-client":
        exporters_length = {
            exporter: len(data)
            for exporter, data in monitoring_stack.get("prometheus", {})
            .get("exporters", {})
            .items()
        }
        for exporter, length in exporters_length.items():
            print(parameter(f"NB Exporters ({exporter})", length))

    view = common_fields(subtype, zone_data)

    if subtype == "monitoring-stack-client":
        view |= {
            "Namespace (main)": namespace,
            "Namespace (probes)": f"probes-obs-{client}",
            "Namespace (rules)": f"rules-obs-{client}",
            "Alertmanager notifications targets": alertmanager_notifications_targets,
            "Retentions (raw / 5m / 1h)": f"{retention_raw} / {retention_5m} / {retention_1h}",
        }

    elif subtype == "monitoring-stack":
        view |= {
            "Namespace": namespace,
            "Alertmanager notifications targets": alertmanager_notifications_targets,
            "Retentions (raw / 5m / 1h)": f"{retention_raw} / {retention_5m} / {retention_1h}",
        }

    return view


def print_view(subtype, view):
    print(header(subtype))
    for field, value in view.items():
        print(parameter(field, value))
    print("\n")


def main():
    try:
        if argv[1] in ["-h", "--help", "help"]:
            print_help()
            exit(0)

        if argv[1] in ["--version", "version"]:
            print_version()
            exit(0)

        client = argv[1]
        zones = get_zones()
    except IndexError:
        help(stderr)
        exit(1)
    except KeyError:
        print("no zone ...", file=stderr)
        exit(1)

    contract = f"obs-{client}"
    subtypes = {
        "grafana",
        "grafana-client",
        "loki",
        "loki-client",
        "monitoring-stack",
        "monitoring-stack-client",
    }

    print_services(client, filter_services(zones, contract, subtypes))


if __name__ == "__main__":
    main()
