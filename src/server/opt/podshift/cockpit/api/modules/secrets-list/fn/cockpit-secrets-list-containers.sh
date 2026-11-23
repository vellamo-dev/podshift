#!/usr/bin/env bash
# @file: cockpit-secrets-list-containers.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/secrets-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/secrets-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the secret references of every container, stopped ones included.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E52A595891E1:-}" ]]; then
    DIR_E52A595891E1="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E52A595891E1
fi

# @description: Prints the secret references of every container, stopped ones included.
# @details:
#   IDs come from podman ps -a --format json, then one podman container inspect reads them all, or
#   one per container when that fails, leaving out a container that cannot be inspected
#   (cockpit-container-inspect-each).
#   Only Id, Name, State, Config.CreateCommand and Config.Secrets are kept, so Config.Env (which
#   older podman versions print with env secret values) is dropped right away.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman or jq fails.
cockpit-secrets-list-containers() {
    local raw ins
    local -a ids
    # shellcheck source=./cockpit-secrets-list-podman.sh
    declare -F cockpit-secrets-list-podman >/dev/null || source "${DIR_E52A595891E1}/cockpit-secrets-list-podman.sh"
    raw="$(cockpit-secrets-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    # shellcheck source=../../../fn/resources/cockpit-container-inspect-each.sh
    declare -F cockpit-container-inspect-each >/dev/null || source "${DIR_E52A595891E1}/../../../fn/resources/cockpit-container-inspect-each.sh"
    ins="$(cockpit-container-inspect-each cockpit-secrets-list-podman "${ids[@]}")"
    printf '%s' "${ins}" | jq -c '[.[]? | objects | {Id, Name, State,
        Config: {CreateCommand: (.Config.CreateCommand? // null), Secrets: (.Config.Secrets? // null)}}]' 2>/dev/null
}
