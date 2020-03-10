#!/bin/sh

usage() {
cat <<EOM
Usage: toolbox <command> [args]

 init                       -- configure initial setup
 doctor                     -- perform sanity checks
 list                       -- list available tools
 update                     -- update all installed tools
 install tool [tool...]     -- install tools globally
 uninstall tool [tool...]   -- uninstall a previously installed tool
 make-shell tool [tool...]  -- create a project dev shell with a list of tools
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
    echo -e "$prefix $args"
}

log-error() {
    local args="$*"
    local prefix="\e[31m[toolbox]:\e[0m"
    echo -e "$prefix $args"
}

log-run() {
    local cmd="$1"
    log "Running \"$cmd\"\n"
    eval $cmd
}

check_args_equal() {
    local actual="$1"
    local expected="$2"
    local cmd="$3"
    if [ "$actual" -ne "$expected" ]; then
        log-error "'$cmd' requires $expected arguments but $actual were given"
        exit 1
    fi
}

check_args_greater() {
    local actual="$1"
    local expected="$2"
    local cmd="$3"
    if [ $actual -lt $expected ]; then
        log-error "'$cmd' requires at least $expected arguments but $actual were given"
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
    nix show-config | grep "toolbox.cachix.org" >/dev/null
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

