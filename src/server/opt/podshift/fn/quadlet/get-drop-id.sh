#!/usr/bin/env bash
# @file: get-drop-id.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Reads the drop ID of a dropped Quadlet file, queued bundle or bundle folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_277224764BE7:-}" ]]; then
    DIR_277224764BE7="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_277224764BE7
fi

# @description: Prints the drop ID from the name of a queued zip or from the "# podshift-drop-id:" line of a file.
# @details:
#   A queued zip carries the ID in its name, shop.zip.<uuid>, with or without a collision suffix
#   after it. A Quadlet file carries it as the line "# podshift-drop-id: <uuid>" (set-drop-id
#   writes it as line 1); the first such line is used. A folder, such as a bundle folder, gives
#   the ID of its first file, in name order, that has one. The ID must be a UUIDv7
#   (is-valid-uuid7).
# @arg: $1 - file or folder.
# @stdout: the ID.
# @exitcode: 0 when an ID was found, 1 when there is none or it is not valid.
get-drop-id() {
    local path name id file
    path="${1-}"
    id=""
    # shellcheck source=../utils/is-valid-uuid7.sh
    declare -F is-valid-uuid7 >/dev/null || source "${DIR_277224764BE7}/../utils/is-valid-uuid7.sh"
    name="$(basename -- "${path}")"
    [[ "${name}" =~ ^(.+)\.[0-9]+$ ]] && name="${BASH_REMATCH[1]}"
    if [[ "${name}" == *.zip.* ]]; then
        id="${name##*.zip.}"
    elif [[ -f "${path}" ]]; then
        id="$(sed -n 's/^# podshift-drop-id: \([0-9a-f-]*\).*$/\1/p' "${path}" 2>/dev/null | head -n 1)"
    elif [[ -d "${path}" ]]; then
        while IFS= read -r file; do
            id="$(get-drop-id "${file}")" && break
            id=""
        done < <(find "${path}" -mindepth 1 -maxdepth 1 -type f | LC_ALL=C sort)
    fi
    is-valid-uuid7 "${id}" || return 1
    printf '%s\n' "${id}"
}
