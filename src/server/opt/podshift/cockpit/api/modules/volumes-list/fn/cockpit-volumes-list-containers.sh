#!/usr/bin/env bash
# @file: cockpit-volumes-list-containers.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman ps -a JSON for every container, each with the names of the volumes it mounts.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5E23D4C026D5:-}" ]]; then
    DIR_5E23D4C026D5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5E23D4C026D5
fi

# @description: Prints podman ps -a JSON for every container, each with the names of the volumes it mounts.
# @details:
#   podman ps lists only mount destinations, so the volume names come from podman container
#   inspect (.Mounts entries of type volume) and are added as VolumeNames.
#   A container that cannot be inspected gets no VolumeNames (cockpit-container-inspect-each).
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman or jq fails.
cockpit-volumes-list-containers() {
    local raw mounts
    local -a ids
    # shellcheck source=./cockpit-volumes-list-podman.sh
    declare -F cockpit-volumes-list-podman >/dev/null || source "${DIR_5E23D4C026D5}/cockpit-volumes-list-podman.sh"
    raw="$(cockpit-volumes-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    # shellcheck source=../../../fn/resources/cockpit-container-inspect-each.sh
    declare -F cockpit-container-inspect-each >/dev/null || source "${DIR_5E23D4C026D5}/../../../fn/resources/cockpit-container-inspect-each.sh"
    mounts="$(cockpit-container-inspect-each cockpit-volumes-list-podman "${ids[@]}")"
    # The JSON is read from files, not arguments: Linux limits one argument to 128 KB.
    jq -n -c --slurpfile ps <(printf '%s' "${raw}") --slurpfile ins <(printf '%s' "${mounts}") '
        def one: if length == 1 then .[0] else error("not one JSON value") end;
        ($ps | one) as $ps | ($ins | one) as $ins |
        ([$ins[]? | {key: ((.Id // "") | tostring),
            value: [(.Mounts // [])[] | objects | select((.Type // "") == "volume") | .Name // empty]}]
            | from_entries) as $m
        | [$ps[] | . + {VolumeNames: ($m[(.Id // "") | tostring] // [])}]
    '
}
