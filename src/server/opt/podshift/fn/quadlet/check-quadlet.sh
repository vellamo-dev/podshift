#!/usr/bin/env bash
# @file: check-quadlet.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Checks a quadlet file against the pattern of its extension.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_DA62C4D7A7A0:-}" ]]; then
    DIR_DA62C4D7A7A0="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DA62C4D7A7A0
fi

# @description: Checks that the file parses and matches each line of pattern-<ext>.conf in order.
# @details:
#   Checks first that the file parses, then checks each line of pattern-<ext>.conf in order,
#   stopping at the first failure. A trailing all-digits suffix (a collision rename such as
#   app.container.1698400000123456789) is removed from the name first.
# @arg: $1 - quadlet file.
# @stdout: on failure, one line: "<name>: no pattern for .<ext>", the parse error, or the section problem.
# @exitcode: 0 if valid, 1 otherwise.
check-quadlet() {
    local file name extension pattern_file sections line
    local -a words
    file="${1}"
    name="$(basename -- "${file}")"
    [[ "${name}" =~ ^(.+)\.[0-9]+$ ]] && name="${BASH_REMATCH[1]}"
    extension=""
    [[ "${name}" == *.* ]] && extension="${name##*.}"
    pattern_file="${DIR_DA62C4D7A7A0}/../../assets/quadlets-validator/patterns/pattern-${extension}.conf"

    if [[ -z "${extension}" || ! -f "${pattern_file}" ]]; then
        echo "${name}: no pattern for .${extension}"
        return 1
    fi

    # shellcheck source=./get-quadlet-ini.sh
    declare -F get-quadlet-ini >/dev/null || source "${DIR_DA62C4D7A7A0}/get-quadlet-ini.sh"
    if ! sections="$(get-quadlet-ini "${file}")"; then
        echo "${name}: ${sections}"
        return 1
    fi

    # shellcheck source=./check-quadlet-section.sh
    declare -F check-quadlet-section >/dev/null || source "${DIR_DA62C4D7A7A0}/check-quadlet-section.sh"
    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" == "#"* ]] && continue
        read -r -a words <<< "${line}"
        (( ${#words[@]} > 0 )) || continue
        check-quadlet-section "${file}" "${name}" "${words[@]}" || return 1
    done < "${pattern_file}"
    return 0
}
