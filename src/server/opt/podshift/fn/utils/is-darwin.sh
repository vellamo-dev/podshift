#!/usr/bin/env bash
# @file: is-darwin.sh
# @dir: /opt/podshift/fn/utils
# @group: utils
# @description: Detects whether the running system is macOS (Darwin).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the running system is macOS (Darwin).
# @exitcode: 0 if Darwin, 1 otherwise.
is-darwin() {
    local kernel_name
    kernel_name="$(uname -s)"
    [[ "${kernel_name}" == "Darwin" ]]
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-darwin
fi
