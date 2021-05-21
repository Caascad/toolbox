#!/usr/bin/env bash
# shellcheck disable=SC1117

set -e
set -o pipefail

REPO_OWNER="Caascad"
REPO_NAME="toolbox"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"

#
# utility functions
#

log() {
    local args="$*"
    local prefix="\x1B[32m[toolbox]:\x1B[0m"
    echo -e "$prefix $args"
}

log-warning() {
    local args="$*"
    local prefix="\x1B[33m[toolbox]:\x1B[0m"
    echo -e "$prefix $args" >&2
}

log-error() {
    local args="$*"
    local prefix="\x1B[31m[toolbox]:\x1B[0m"
    echo -e "$prefix $args" >&2
    exit 1
}

log-run() {
    local cmd="$1"
    log "Running \"$cmd\"\n"
    eval "$cmd"
}

check_args_eq() {
    local actual="$1"
    local expected="$2"
    local cmd="$3"
    if [ "$actual" -ne "$expected" ]; then
        log-error "'$cmd' requires $expected arguments but $actual were given"
        exit 1
    fi
}

check_args_gt() {
    local actual="$1"
    local expected="$2"
    local cmd="$3"
    if [ "$actual" -lt "$expected" ]; then
        log-error "'$cmd' requires at least $expected arguments but $actual were given"
        exit 1
    fi
}

check_args_le() {
    local actual="$1"
    local expected="$2"
    local cmd="$3"
    if [ "$actual" -gt "$expected" ]; then
        log-error "'$cmd' wants at most $expected arguments but $actual were given"
        exit 1
    fi
}

_lastToolboxCommit() {
    curl -s https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/branches/master | jq -r '.commit.sha'
}

_currentShellCommit() {
    [ -f toolbox.json ] && jq -e -r .commit toolbox.json
}

_commitArchiveURL() {
    local sha=$1
    echo "${REPO_URL}/archive/${sha}.tar.gz"
}

_generateToolboxJSON() {
    commit=$1
    if [ "$(_currentShellCommit)" == "${commit}" ]; then
        log "Shell is already up-to-date!"
        return
    fi
    url=$(_commitArchiveURL "$commit")
    log "Using commit $commit for this development shell"
    log "Calculating sha256 for $url"
    sha256=$(nix-prefetch-url --unpack "$url" 2>/dev/null) || log-error "Download failed. Wrong commit?"

    if [ ! -f toolbox.json ]; then
        log "Writing toolbox.json file"
        cat <<EOF > toolbox.json
{
    "epoch": 1,
    "commit": "$commit",
    "sha256": "$sha256"
}
EOF
    else
        tmp=$(mktemp)
        log "Updating toolbox.json file ..."
        jq -e ".commit=\"${commit}\" | .sha256=\"${sha256}\"" toolbox.json > "$tmp"
        # shellcheck disable=SC2015,SC2181
        [ $? -eq 0 ] && mv "$tmp" toolbox.json || log-error "Failed to update toolbox.json"
        log "Done."
    fi
}

#
# sanity check functions
#

_isRegularUser() {
    test "$(id -u)" -ne 0
}

_sourceNix() {
    NIX_SH="$HOME/.nix-profile/etc/profile.d/nix.sh"
    # shellcheck disable=SC1090,SC2015
    test -f "$NIX_SH" && source "$NIX_SH" || true
}

_isNixInstalled() {
    nix --version >/dev/null 2>&1
}

_isSubstituterConfigured() {
    nix show-config | grep -q "toolbox.cachix.org"
}

_isChannelInstalled() {
    nix-channel --list | grep -q toolbox
}

#
# subcommands
#

usage() {
  cat <<EOF
Usage: toolbox <command> [args]

 doctor                        -- perform sanity checks
 list                          -- list available tools
 update                        -- update all globally installed tools
 install tool [tool...]        -- install tools globally
 uninstall tool [tool...]      -- uninstall a previously installed tool
 make-shell tool [tool...]     -- create a project dev shell with a list of tools
 update-shell                  -- update toolbox revision for an existing shell
 completions                   -- output completion script
 help                          -- this help
 version                       -- show toolbox version

Terraform related commands:

 list-terraform-providers                       -- list available terraform providers
 make-terraform12-shell provider [provider...]  -- create a terraform 0.12 shell with the specified providers
 make-terraform13-shell provider [provider...]  -- create a terraform 0.13 shell with the specified providers
 make-terraform14-shell provider [provider...]  -- create a terraform 0.14 shell with the specified providers
 make-terraform15-shell provider [provider...]  -- create a terraform 0.15 shell with the specified providers

EOF
}

completions() {
  cat <<EOF
NIX_SH="\$HOME/.nix-profile/etc/profile.d/nix.sh"

test -f "\$NIX_SH" && source "\$NIX_SH"

_get_toolbox_attrs() {
  nix-instantiate --strict --eval --expr "builtins.attrNames (import <toolbox> {})" | tr -d "[]\""
}

_get_terraform_providers_attrs() {
  nix-instantiate --strict --eval --expr "builtins.attrNames (import <toolbox> {}).pkgs.terraform-providers" | tr -d "[]\""
}

_toolbox_completions() {
  local cur="\${COMP_WORDS[COMP_CWORD]}"
  local prev="\${COMP_WORDS[COMP_CWORD-1]}"

  if [ "\${#COMP_WORDS[@]}" = "2" ]; then
      COMPREPLY=(\$(compgen -W "doctor completions list list-terraform-providers install uninstall update make-shell update-shell make-terraform12-shell make-terraform13-shell make-terraform14-shell make-terraform15-shell help version" "\${COMP_WORDS[1]}"))
      return
  fi

  # Without nix-instantiate we cannot retrieve any
  # suggestions
  if ! type nix-instantiate >/dev/null 2>&1; then
      return
  fi

  case "\$prev" in
      uninstall|install|make-shell)
          COMPREPLY=(\$(compgen -W "\$(_get_toolbox_attrs)" "\$cur"))
          ;;
      make-terraform*)
          COMPREPLY=(\$(compgen -W "\$(_get_terraform_providers_attrs)" "\$cur"))
          ;;
  esac
}

complete -F _toolbox_completions toolbox
EOF
}

version() {
    nix-env -f '<toolbox>' -q toolbox --json | jq -r '.[].version'
}

doctor() {
    OK="\x1B[32mOK\x1B[0m"
    X="\x1B[31mX\x1B[0m"
    FAIL=""

    log "Running sanity checks:\n"

    if _isNixInstalled
    then
        echo -e "- Nix installed : $OK"
    else
        echo -e "- Nix installed : $X"
        FAIL="."
    fi

    if _isSubstituterConfigured
    then
        echo -e "- toolbox binary cache : $OK"
    else
        echo -e "- toolbox binary cache : $X"
        FAIL="."
    fi

    if _isChannelInstalled
    then
        echo -e "- toolbox channel : $OK"
    else
        echo -e "- toolbox channel : $X"
        FAIL="."
    fi

    if [[ $FAIL = "" ]]; then
        echo -e "\nAll essential tests passed."
    else
        echo -e "\nSome tests failed. Try to reinstall the toolbox:\n"
        echo "curl https://raw.githubusercontent.com/Caascad/toolbox/master/install | sh"
        exit 1
    fi
}

list() {
    cat <(echo -e "Package#Available#Installed#Description") \
        <(nix-env -f '<toolbox>' -q -a -P -c --description \
        | sed 's/^\([^ ]*\)[[:space:]]\+[a-z0-9-]\+[a-z-]\([^ ]\+\)[[:space:]]\+\(. [^ ]\+\)[[:space:]]\+\(.*\)/\1#\2#\3#\4/') \
    | column -s '#' -t | grep --color -E '^|>|<'
}

list-terraform-providers() {
    nix-instantiate --eval -E 'with import <toolbox> {}; builtins.attrNames (pkgs.lib.filterAttrs (_: d: pkgs.lib.isDerivation d) pkgs.terraform-providers)' --json | jq .[] -r
}

install() {
    local pkgs="$*"
    log-run "nix-env -f '<toolbox>' -iA $pkgs"
}

uninstall() {
    local pkgs="$*"
    log-run "nix-env -e $pkgs"
}

update() {
    log "Updating toolbox ..."
    log-run "nix-channel --update toolbox"
    log-run "nix-env -f '<toolbox>' -u -b"
}

make-shell() {
    log "Creating shell ..."
    commit=${GITHUB_SHA:-$(_lastToolboxCommit)}
    _generateToolboxJSON "${commit}"

    log "Writing shell.nix file"
    cat <<EOF > shell.nix
# Generated by: toolbox make-shell ${@}
let
  toolboxSrc = builtins.fromJSON (builtins.readFile ./toolbox.json);
  toolbox = import (builtins.fetchTarball {
    url = "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/\${toolboxSrc.commit}.tar.gz";
    sha256 = toolboxSrc.sha256;
  }) {};
in with toolbox; pkgs.runCommand "deps" {
  buildInputs = [
    ${@}
  ];
} ""
EOF
    # Evaluate shell.nix to check that all requested attributes are valid
    result=$(nix-instantiate shell.nix 2>&1 | grep error || true)
    # If not, parse error message to show the culprit
    if [ -n "$result" ]; then
        # shellcheck disable=SC2001
        log-error "Error: '$(echo "$result" | sed "s/^error: undefined variable '\([^']*\)'.*$/\1/")' is not available in the toolbox"
    fi

    log "To activate the development shell:"
    log " - add 'use_nix' in an .envrc file to load tools with direnv"
    log " - or run 'nix-shell' to spawn a new shell with the tools"
    log "Don't forget to commit shell.nix and toolbox.json in your project."
}

update-shell() {
    if [ -f shell.nix ] && [ ! -f toolbox.json ]; then
        log-warning "Shells are now created with a different method."
        log-warning "You need to use the 'make-shell' command to recreate your shell."
        log-warning "After that you will be able to use 'update-shell'."
        exit 1
    fi
    if [ ! -f shell.nix ]; then
        log-error "I don't see any 'shell.nix' in this directory, aborting."
    fi
    log "Updating shell ..."
    commit=${1:-$(_lastToolboxCommit)}
    _generateToolboxJSON "$commit"
}

generate-terraform-tf() {
    log "Generating terraform.tf..."
    cat <<EOF > terraform.tf
terraform {
  required_providers {
EOF
    providers=$*
    for p in $providers
    do
        source_addr=$(nix-instantiate --eval -E "with import <toolbox> {}; pkgs.terraform-providers.${p}.passthru.provider-source-address" | jq -r | cut -d'/' -f2-3)
        cat <<EOF >> terraform.tf
    ${p} = {
      source = "${source_addr}"
    }
EOF
    done
    cat <<EOF >> terraform.tf
  }
}
EOF
}

make-terraform-shell() {
    version=$1
    shift
    providers=("$@")
    nix_providers=""
    for p in "${providers[@]}"
    do
        nix_providers="${nix_providers} p.${p}"
    done
    log "Creating terraform ${version} shell with providers: ${providers[*]}"
    make-shell "(terraform_${version/./_}.withPlugins (p: [${nix_providers}]))"

    case "$version" in
        0.13|0.14)
            generate-terraform-tf "${providers[@]}"
            ;;
    esac
}

#
# main
#

if ! _isRegularUser; then
    log-error "Root user detected. Run ./toolbox as non-root user!"
    exit 1
fi

if [ -z "${1:-}" ]; then
    usage
    exit 1
fi

_sourceNix

PARAMS=""

while (( "$#" )); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -*) # unsupported flags
      log-error "Error: unsupported flag $1"
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

COMMAND="$1"
shift

case "$COMMAND" in
    doctor)
        doctor
        ;;
    completions)
        completions
        ;;
    list)
        list
        ;;
    list-terraform-providers)
        list-terraform-providers
        ;;
    install)
        check_args_gt $# 1 "install"
        install "$@"
        ;;
    uninstall)
        check_args_gt $# 1 "uninstall"
        uninstall "$@"
        ;;
    update)
        update
        ;;
    make-shell)
        check_args_gt $# 1 "make-shell"
        make-shell "$@"
        ;;
    update-shell)
        check_args_le $# 1 "update-shell"
        update-shell "$@"
        ;;
    make-terraform-shell)
        log-error "make-terraform-shell has been removed, use make-terraform<VERSION>-shell"
        exit 1
        ;;
    make-terraform12-shell)
        check_args_gt $# 1 "make-terraform12-shell"
        log-warning "Consider using a newer version of terraform (0.15)"
        make-terraform-shell 0.12 "$@"
        ;;
    make-terraform13-shell)
        check_args_gt $# 1 "make-terraform13-shell"
        log-warning "Consider using a newer version of terraform (0.15)"
        make-terraform-shell 0.13 "$@"
        ;;
    make-terraform14-shell)
        check_args_gt $# 1 "make-terraform14-shell"
        log-warning "Consider using a newer version of terraform (0.15)"
        make-terraform-shell 0.14 "$@"
        ;;
    make-terraform15-shell)
        check_args_gt $# 1 "make-terraform15-shell"
        make-terraform-shell 0.15 "$@"
        ;;
    help)
        usage
        ;;
    version)
        version
        ;;
    *)
        log-warning "Error: unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
