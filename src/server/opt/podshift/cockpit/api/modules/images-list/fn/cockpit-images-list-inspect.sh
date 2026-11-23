#!/usr/bin/env bash
# @file: cockpit-images-list-inspect.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/images-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/images-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman image inspect JSON for every image of the current (podshift) user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8307B7560CF2:-}" ]]; then
    DIR_8307B7560CF2="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8307B7560CF2
fi

# @description: Prints podman image inspect JSON for every image of the current (podshift) user.
# @details:
#   IDs come from podman image ls --format json. With no images the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-images-list-inspect() {
    local raw
    local -a ids
    # shellcheck source=./cockpit-images-list-podman.sh
    declare -F cockpit-images-list-podman >/dev/null || source "${DIR_8307B7560CF2}/cockpit-images-list-podman.sh"
    raw="$(cockpit-images-list-podman image ls --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    cockpit-images-list-podman image inspect -- "${ids[@]}" 2>/dev/null
}
