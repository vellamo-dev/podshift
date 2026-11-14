#!/usr/bin/env bash
# @file: example-network-lines.sh
# @source-dir: src/test/cli/shared/fn/vm
# @group: test
# @category: helper
# @description: Reads the example unmanaged network list.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the usable lines of unmanaged.list: no blank lines, no comments, only example- names.
# @arg: $1 - path of unmanaged.list.
# @stdout: one line per network, <name> <options>.
# @exitcode: 0 if the file was read, 1 if it is missing.
example-network-lines() {
    local file line
    file="${1}"
    [[ -f "${file}" ]] || return 1
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -n "${line}" && "${line}" != \#* ]] || continue
        [[ "${line}" == example-* ]] || continue
        printf '%s\n' "${line}"
    done < "${file}"
    return 0
}
