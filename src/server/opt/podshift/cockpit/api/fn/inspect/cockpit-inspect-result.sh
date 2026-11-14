#!/usr/bin/env bash
# @file: cockpit-inspect-result.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/inspect
# @dest-dir: /opt/podshift/cockpit/api/fn/inspect
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the inspect action data from the JSON array that podman inspect prints.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {kind, ref, found, object} from podman inspect JSON, or a too-large result.
# @details:
#   object is the first element of the array and is left out when the array is empty, which
#   means the resource was not found. The object is passed on as podman printed it. When the
#   compact result line, newline included, is longer than the byte limit, object is left out and
#   tooLarge is true, with size set to the bytes of the object as pretty JSON (4-space indent),
#   which is what file mode writes.
# @arg: $1 - kind: container, image, volume, network or secret.
# @arg: $2 - ref as requested.
# @arg: $3 - JSON array from podman <kind> inspect, or [] when the resource does not exist.
# @arg: $4 - byte limit of the result line, for example 131072.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 when the input is not a JSON array of objects or the limit is not a number.
cockpit-inspect-result() {
    local kind ref raw limit out bytes size
    kind="${1-}"
    ref="${2-}"
    raw="${3-}"
    limit="${4-}"
    [[ -n "${kind}" && -n "${ref}" && -n "${raw}" ]] || return 1
    [[ "${limit}" =~ ^[0-9]+$ ]] || return 1
    out="$(printf '%s' "${raw}" | jq -c -e --arg kind "${kind}" --arg ref "${ref}" '
        if type != "array" then error("not an array")
        elif length == 0 then {kind: $kind, ref: $ref, found: false}
        elif (.[0] | type) != "object" then error("not an object")
        else {kind: $kind, ref: $ref, found: true, object: .[0]}
        end
    ' 2>/dev/null)" || return 1
    bytes="$(printf '%s\n' "${out}" | LC_ALL=C wc -c | tr -d '[:space:]')"
    if (( bytes <= limit )); then
        printf '%s\n' "${out}"
        return 0
    fi
    size="$(printf '%s' "${raw}" | jq --indent 4 '.[0]' 2>/dev/null | LC_ALL=C wc -c | tr -d '[:space:]')" || return 1
    [[ "${size}" =~ ^[0-9]+$ ]] || return 1
    jq -n -c --arg kind "${kind}" --arg ref "${ref}" --argjson size "${size}" \
        '{kind: $kind, ref: $ref, found: true, tooLarge: true, size: $size}'
}
