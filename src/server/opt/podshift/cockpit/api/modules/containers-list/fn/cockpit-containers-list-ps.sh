#!/usr/bin/env bash
# @file: cockpit-containers-list-ps.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman ps -a JSON for every container of the current (podshift) user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A7FFABDA5FDD:-}" ]]; then
    DIR_A7FFABDA5FDD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A7FFABDA5FDD
fi

# @description: Prints podman ps -a JSON for every container of the current (podshift) user.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-containers-list-ps() {
    local raw
    # shellcheck source=./cockpit-containers-list-podman.sh
    declare -F cockpit-containers-list-podman >/dev/null || source "${DIR_A7FFABDA5FDD}/cockpit-containers-list-podman.sh"
    raw="$(cockpit-containers-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    printf '%s\n' "${raw}"
}
