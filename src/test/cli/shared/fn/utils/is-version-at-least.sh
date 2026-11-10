#!/usr/bin/env bash
# @file: is-version-at-least.sh
# @source-dir: src/test/cli/shared/fn/utils
# @group: test
# @category: helper
# @description: Compares two dotted version numbers.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Tells whether a version is the same as or newer than a minimum, for example 1.5.0 and 1.4.2.
# @arg: $1 - the version found.
# @arg: $2 - the minimum version.
# @exitcode: 0 if the found version is new enough, 1 otherwise.
is-version-at-least() {
    local found minimum i
    local -a f m
    found="${1}"
    minimum="${2}"
    IFS=. read -r -a f <<< "${found}"
    IFS=. read -r -a m <<< "${minimum}"
    for i in 0 1 2; do
        [[ "$((10#${f[i]:-0}))" -gt "$((10#${m[i]:-0}))" ]] && return 0
        [[ "$((10#${f[i]:-0}))" -lt "$((10#${m[i]:-0}))" ]] && return 1
    done
    return 0
}
