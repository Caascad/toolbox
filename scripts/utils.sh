#!/bin/sh

REPO_OWNER="Caascad"
REPO_NAME="toolbox"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"

usage() {
cat <<EOM
Usage: toolbox <command> [args]

 init                       -- configure initial setup
 doctor                     -- perform sanity checks
 list                       -- list available tools
 update                     -- update all globally installed tools
 install tool [tool...]     -- install tools globally
 uninstall tool [tool...]   -- uninstall a previously installed tool
 make-shell tool [tool...]  -- create a project dev shell with a list of tools
 update-shell               -- update toolbox revision for an existing shell
 completions                -- output completion script
 help                       -- this help

EOM
}


log() {
    local args="$*"
    local prefix="\e[32m[toolbox]:\e[0m"
    echo -e "$prefix $args"
}

log-warning() {
    local args="$*"
    local prefix="\e[33m[toolbox]:\e[0m"
    echo -e "$prefix $args" >&2
}

log-error() {
    local args="$*"
    local prefix="\e[31m[toolbox]:\e[0m"
    echo -e "$prefix $args" >&2
    exit 1
}

log-run() {
    local cmd="$1"
    log "Running \"$cmd\"\n"
    eval $cmd
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
    if [ $actual -lt $expected ]; then
        log-error "'$cmd' requires at least $expected arguments but $actual were given"
        exit 1
    fi
}

check_args_le() {
    local actual="$1"
    local expected="$2"
    local cmd="$3"
    if [ $actual -gt $expected ]; then
        log-error "'$cmd' wants at most $expected arguments but $actual were given"
        exit 1
    fi
}

#
# sanity check functions
#

_isRegularUser() {
    test $(id -u) -ne 0
}

_hasKvmSupport() {
    test -c /dev/kvm && test -w /dev/kvm && test -r /dev/kvm
}

_isNixInstalled() {
    nix --version >/dev/null 2>&1
}

_sourceNix() {
    NIX_SH="$HOME/.nix-profile/etc/profile.d/nix.sh"
    test -f "$NIX_SH" && source "$NIX_SH" || true
}

_isSubstituterConfigured() {
    nix show-config | grep -q "toolbox.cachix.org"
}

_isChannelInstalled() {
    nix-channel --list | grep -q toolbox
}

_addCacheConfig() {
    if test -f ~/.config/nix/nix.conf
    then
        log-warning "$HOME/.config/nix/nix.conf exists."
        log "Please add the following binary cache:"
        log " substituters = https://toolbox.cachix.org"
        log " trusted-public-keys = toolbox.cachix.org-1:ZFzO+86jD4G5ukgmLOnQRxjVmMcqu+60JTusH6pv8/8="
    else
        mkdir -p "$HOME"/.config/nix/
        cat << EOF > "$HOME"/.config/nix/nix.conf
substituters = https://cache.nixos.org https://toolbox.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= toolbox.cachix.org-1:ZFzO+86jD4G5ukgmLOnQRxjVmMcqu+60JTusH6pv8/8=
EOF
    fi
}

_currentCommit() {
    [ -f toolbox.json ] && jq -e -r .commit toolbox.json
}

_lastCommit() {
    curl -s https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/branches/master | jq -r '.commit.sha'
}

_commitArchiveURL() {
    local sha=$1
    echo "${REPO_URL}/archive/${sha}.tar.gz"
}

_generateToolboxJSON() {
    commit=$1
    if [ "$(_currentCommit)" == "${commit}" ]; then
        log "Shell is already up-to-date!"
        return
    fi
    url=$(_commitArchiveURL $commit)
    log "Using commit $commit for this development shell"
    log "Calculating sha256 for $url"
    sha256=$(nix-prefetch-url --unpack $url 2>/dev/null) || log-error "Download failed. Wrong commit?"

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
        jq -e ".commit=\"${commit}\" | .sha256=\"${sha256}\"" toolbox.json > $tmp
        [ $? -eq 0 ] && mv $tmp toolbox.json || log-error "Failed to update toolbox.json"
        log "Done."
    fi
}
