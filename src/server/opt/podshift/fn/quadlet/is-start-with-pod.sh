#!/usr/bin/env bash
# @file: is-start-with-pod.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Tells if a quadlet file sets StartWithPod= to a true value.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether the last StartWithPod= line of the file has a true value.
# @details:
#   The value is true if it is true, yes, 1 or on, in any case. A file without the key, or with
#   another value, is not true.
# @arg: $1 - quadlet file.
# @stdout: nothing.
# @exitcode: 0 if StartWithPod= is true, 1 if not or if the file cannot be read.
is-start-with-pod() {
    local file line value
    file="${1-}"
    [[ -f "${file}" && -r "${file}" ]] || return 1
    line="$(grep -E -- '^[[:space:]]*StartWithPod[[:space:]]*=' "${file}" | tail -n 1)"
    [[ -n "${line}" ]] || return 1
    value="$(printf '%s' "${line#*=}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    [[ "${value}" == "true" || "${value}" == "yes" || "${value}" == "1" || "${value}" == "on" ]]
}
