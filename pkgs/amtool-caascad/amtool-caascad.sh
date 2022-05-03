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
HTTP_CONFIG_FILE_DIR="${HOME}/.config/amtool-caascad/cache"

show_help() {
    cat <<EOHELP
amtool-wrapper help

This is a wrapper for amtool. Here are the specific options for the wrapper :

  --alertmanager.url : Also accepts "<zone>/<subzone>" format, where <subzone> is one of "caascad", "client", "app" or "consumption".
                       When a regular URI is specified, it will be used as is.

  --http.config.file : HTTP configuration file as needed by amtool.
                       However, when it is not specified, and when --alertmanager.url="<zone>/<subzone>", it will
                       be generated.
                       When it is explicitely specified, it will override the generated one.
                       This can be useful when using the same token across multiple calls to Amtool.

  --help             : Show this help before amtool help.
  --version          : Show the version of the wrapper before amtool version

EOHELP
}

parse_url() {
    ZONE=""
    SUBZONE=""

    # Check the format of $1
    case "$1" in
        http*)
            ;;
        */*)
            ZONE=$(echo "$url" | cut -d/ -f 1)
            SUBZONE=$(echo "$url" | cut -d/ -f 2)
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
        echo "In <zone>/<subzone>, subzone should be one of 'caascad', 'client', 'app' or 'consumption'. Got '${SUBZONE}'" 1>&2
        exit 1
    fi

    url="--alertmanager.url=https://rancher.${ZONE}.caascad.com/k8s/clusters/local/api/v1/namespaces/${namespace}/services/${service}:9093/proxy"
    echo "$url"
}

build_httpconfig() {
    # Check if httpconfig file exists
    http_config_file_path="$1"
    if [ -e "${http_config_file_path}" ]; then
        return
    fi

    # Connect to vault
    export VAULT_ADDR=https://vault.${ZONE}.caascad.com
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
