#!/usr/bin/env bash
# print-warning.sh
# /usr/local/etc/podshift/fn/utils

# Prints a warning message to stderr in bold yellow.
print-warning() {
    local message
    message="${1}"
    echo -e "\033[1;33mWarning: ${message}\033[0m" >&2
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && print-warning "${2}"
fi
