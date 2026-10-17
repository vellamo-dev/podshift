#!/usr/bin/env bash
# is-darwin.sh
# /usr/local/etc/podshift/fn/utils

# Returns 0 (true) if the running system is macOS (Darwin), non-zero otherwise.
is-darwin() {
    local kernel_name
    kernel_name="$(uname -s)"
    [[ "${kernel_name}" == "Darwin" ]]
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-darwin
fi
