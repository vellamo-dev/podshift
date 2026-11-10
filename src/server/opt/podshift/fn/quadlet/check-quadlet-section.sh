#!/usr/bin/env bash
# @file: check-quadlet-section.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Checks one section of a quadlet and its required keys.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_9ECDD8DB08EB:-}" ]]; then
    DIR_9ECDD8DB08EB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_9ECDD8DB08EB
fi

# @description: Checks with get-quadlet-ini, case-sensitive, that the section exists and every key has a non-empty value.
# @arg: $1 - quadlet file.
# @arg: $2 - the name shown in the message.
# @arg: $3 - the section name.
# @arg: $4 - the required keys, one per argument (optional).
# @stdout: on failure, one line: "<name>: missing [<Section>]", "<name>: [<Section>] missing Key1, Key2", "<name>: bad line N" or "<name>: cannot read".
# @exitcode: 0 if valid, 1 otherwise.
check-quadlet-section() {
    local file name section sections present key missing
    local -a keys
    file="${1}"
    name="${2}"
    section="${3}"
    keys=("${@:4}")
    # shellcheck source=./get-quadlet-ini.sh
    declare -F get-quadlet-ini >/dev/null || source "${DIR_9ECDD8DB08EB}/get-quadlet-ini.sh"
    if ! sections="$(get-quadlet-ini "${file}")"; then
        echo "${name}: ${sections}"
        return 1
    fi
    if ! grep -Fxq -- "${section}" <<< "${sections}"; then
        echo "${name}: missing [${section}]"
        return 1
    fi
    present="$(get-quadlet-ini "${file}" "${section}")"
    missing=""
    for key in "${keys[@]}"; do
        grep -Fxq -- "${key}" <<< "${present}" || missing+="${missing:+, }${key}"
    done
    if [[ -n "${missing}" ]]; then
        echo "${name}: [${section}] missing ${missing}"
        return 1
    fi
    return 0
}
