#!/usr/bin/env bash
# @file: is-podshift.sh
# @dir: /opt/podshift/fn/utils
# @group: utils
# @description: Detects whether the current user is the dedicated podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the current user is the podshift user (UID 300).
# @exitcode: 0 if podshift user, 1 otherwise.
is-podshift() {
    [[ "${EUID}" -eq 300 ]]
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-podshift
fi
