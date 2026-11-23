#!/usr/bin/env bash
# @file: cockpit-containers-list-inspect.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman container inspect JSON for every container in a podman ps array, skipping broken ones.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_6BCC876DBCFD:-}" ]]; then
    DIR_6BCC876DBCFD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_6BCC876DBCFD
fi

# @description: Prints podman container inspect JSON for every container in a podman ps array, skipping broken ones.
# @details:
#   One call for all containers, or one per container when that fails (cockpit-container-inspect-each).
# @arg: $1 - JSON array from podman ps -a --format json.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 always.
cockpit-containers-list-inspect() {
    local raw
    local -a ids
    # shellcheck source=./cockpit-containers-list-podman.sh
    declare -F cockpit-containers-list-podman >/dev/null || source "${DIR_6BCC876DBCFD}/cockpit-containers-list-podman.sh"
    raw="${1-}"
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    # shellcheck source=../../../fn/resources/cockpit-container-inspect-each.sh
    declare -F cockpit-container-inspect-each >/dev/null || source "${DIR_6BCC876DBCFD}/../../../fn/resources/cockpit-container-inspect-each.sh"
    cockpit-container-inspect-each cockpit-containers-list-podman "${ids[@]}"
}
