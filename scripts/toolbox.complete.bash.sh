NIX_SH="$HOME/.nix-profile/etc/profile.d/nix.sh"

test -f "$NIX_SH" && source "$NIX_SH"

_get_attrs()
{
    nix-instantiate --strict --eval --expr "builtins.attrNames (import $ENTRYPOINT {})" | tr -d "[]\""
}

_toolbox_completions()
{
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ "${#COMP_WORDS[@]}" = "2" ]; then
        COMPREPLY=($(compgen -W "build completions list update uninstall install make-shell init doctor" "${COMP_WORDS[1]}"))
        return
    fi

    # Without nix-instantiate we cannot retrieve any
    # suggestions
    if ! type nix-instantiate >/dev/null 2>&1; then
        return
    fi

    case "$prev" in
        uninstall|install|build|make-shell)
            COMPREPLY=($(compgen -W "$(_get_attrs)" "$cur"))
            ;;
    esac
}

complete -F _toolbox_completions ./toolbox
complete -F _toolbox_completions toolbox
