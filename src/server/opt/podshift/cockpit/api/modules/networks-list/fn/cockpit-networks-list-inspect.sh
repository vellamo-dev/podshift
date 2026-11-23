#!/usr/bin/env bash
# @file: cockpit-networks-list-inspect.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman network inspect JSON for every network of the current (podshift) user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_0A98AF7970DC:-}" ]]; then
    DIR_0A98AF7970DC="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_0A98AF7970DC
fi

# @description: Prints podman network inspect JSON for every network of the current (podshift) user.
# @details:
#   Names come from podman network ls --format json. With no networks the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-networks-list-inspect() {
    local raw
    local -a names
    # shellcheck source=./cockpit-networks-list-podman.sh
    declare -F cockpit-networks-list-podman >/dev/null || source "${DIR_0A98AF7970DC}/cockpit-networks-list-podman.sh"
    raw="$(cockpit-networks-list-podman network ls --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t names < <(printf '%s' "${raw}" | jq -r '.[]? | (.name // .Name // empty)')
    if [[ "${#names[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    cockpit-networks-list-podman network inspect -- "${names[@]}" 2>/dev/null
}
