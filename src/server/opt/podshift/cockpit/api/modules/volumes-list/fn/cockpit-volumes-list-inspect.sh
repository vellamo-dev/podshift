#!/usr/bin/env bash
# @file: cockpit-volumes-list-inspect.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman volume inspect JSON for every volume of the current (podshift) user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4801A0468892:-}" ]]; then
    DIR_4801A0468892="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4801A0468892
fi

# @description: Prints podman volume inspect JSON for every volume of the current (podshift) user.
# @details:
#   Names come from podman volume ls --format json. With no volumes the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-volumes-list-inspect() {
    local raw
    local -a names
    # shellcheck source=./cockpit-volumes-list-podman.sh
    declare -F cockpit-volumes-list-podman >/dev/null || source "${DIR_4801A0468892}/cockpit-volumes-list-podman.sh"
    raw="$(cockpit-volumes-list-podman volume ls --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t names < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Name // .name // empty)] | unique | .[]')
    if [[ "${#names[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    cockpit-volumes-list-podman volume inspect -- "${names[@]}" 2>/dev/null
}
