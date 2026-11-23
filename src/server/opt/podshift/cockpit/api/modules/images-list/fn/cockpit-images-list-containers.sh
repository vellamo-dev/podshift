#!/usr/bin/env bash
# @file: cockpit-images-list-containers.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/images-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/images-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman ps -a JSON for every container of the current (podshift) user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_71783AD4FE8D:-}" ]]; then
    DIR_71783AD4FE8D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_71783AD4FE8D
fi

# @description: Prints podman ps -a JSON for every container of the current (podshift) user.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-images-list-containers() {
    local raw
    # shellcheck source=./cockpit-images-list-podman.sh
    declare -F cockpit-images-list-podman >/dev/null || source "${DIR_71783AD4FE8D}/cockpit-images-list-podman.sh"
    raw="$(cockpit-images-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    printf '%s\n' "${raw}"
}
