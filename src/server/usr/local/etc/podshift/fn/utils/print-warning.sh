#!/usr/bin/env bash
# @file: print-warning.sh
# @dir: /usr/local/etc/podshift/fn/utils
# @group: utils
# @description: Prints a warning message to stderr in bold yellow.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Prints a warning message to stderr in bold yellow.
# @param: $1 - warning message
# @stderr: prints the yellow warning line.
print-warning() {
    local message
    message="${1}"
    echo -e "\033[1;33mWarning: ${message}\033[0m" >&2
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && print-warning "${2}"
fi
