#!/usr/bin/env bash
# @file: cockpit-overview-count.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Formats an overview usage count as a total, as in-use over total, or as 0 when the total is 0.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints a total, or an in-use and total count as "<in-use> / <all>", or 0 when the total is 0.
# @arg: $1 - a non-negative integer: the total when $2 is omitted, otherwise the in-use count.
# @arg: $2 - optional total count, a non-negative integer.
# @stdout: the formatted value, for example 3, 3 / 5, or 0 when the total is 0.
# @exitcode: 0 when the given arguments are non-negative integers, 1 otherwise.
cockpit-overview-count() {
    local used all
    used="${1-}"
    all="${2-}"
    if [[ "$#" -eq 1 ]]; then
        [[ "${used}" =~ ^[0-9]+$ ]] || return 1
        printf '%s\n' "${used}"
        return 0
    fi
    [[ "${used}" =~ ^[0-9]+$ && "${all}" =~ ^[0-9]+$ ]] || return 1
    if [[ "${all}" -eq 0 ]]; then
        printf '0\n'
        return 0
    fi
    printf '%s / %s\n' "${used}" "${all}"
    return 0
}
