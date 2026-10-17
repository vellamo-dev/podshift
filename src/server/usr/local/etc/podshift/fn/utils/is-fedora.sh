#!/usr/bin/env bash
# is-fedora.sh
# /usr/local/etc/podshift/fn/utils

# Returns 0 (true) if the running system is Fedora, non-zero otherwise.
is-fedora() {
    local os_id
    [[ -r /etc/os-release ]] || return 1
    os_id="$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    [[ "${os_id}" == "fedora" ]]
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-fedora
fi
