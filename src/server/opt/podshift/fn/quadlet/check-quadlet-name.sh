#!/usr/bin/env bash
# @file: check-quadlet-name.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Checks that a quadlet sets its name key to the file base name and that the name has no reserved ending.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_DE7E742EDBE4:-}" ]]; then
    DIR_DE7E742EDBE4="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DE7E742EDBE4
fi

# @description: Checks the name rules of one quadlet file and prints the reason when one is broken.
# @details:
#   The base name is the file name without the collision suffix and the extension. It must not end
#   with -pod, -network, -volume, -image or -build, the endings the Quadlet generator adds to the
#   service names (web.pod becomes web-pod.service), for any type. For .container, .network,
#   .volume and .pod the name key (ContainerName, NetworkName, VolumeName, PodName) must be set
#   and equal the base name. Other types, such as .image, go by the file name only.
# @arg: $1 - quadlet file.
# @stdout: on failure, one line: "<name>: ..." with the broken rule.
# @exitcode: 0 if the rules hold, 1 otherwise.
check-quadlet-name() {
    local file name stem extension ending section key value
    local -a pair
    file="${1-}"
    name="$(basename -- "${file}")"
    [[ "${name}" =~ ^(.+)\.[0-9]+$ ]] && name="${BASH_REMATCH[1]}"
    stem="${name%.*}"
    extension="${name##*.}"

    for ending in -pod -network -volume -image -build; do
        if [[ "${stem}" == *"${ending}" ]]; then
            echo "${name}: the name must not end with ${ending}"
            return 1
        fi
    done

    # shellcheck source=./get-quadlet-name-key.sh
    declare -F get-quadlet-name-key >/dev/null || source "${DIR_DE7E742EDBE4}/get-quadlet-name-key.sh"
    read -r -a pair <<< "$(get-quadlet-name-key "${extension}")"
    (( ${#pair[@]} == 2 )) || return 0
    section="${pair[0]}"
    key="${pair[1]}"

    # shellcheck source=./get-quadlet-ini.sh
    declare -F get-quadlet-ini >/dev/null || source "${DIR_DE7E742EDBE4}/get-quadlet-ini.sh"
    if ! value="$(get-quadlet-ini "${file}" "${section}" "${key}")"; then
        echo "${name}: [${section}] missing ${key}"
        return 1
    fi
    if [[ "${value}" != "${stem}" ]]; then
        echo "${name}: ${key} must be ${stem}, not ${value}"
        return 1
    fi
    return 0
}
