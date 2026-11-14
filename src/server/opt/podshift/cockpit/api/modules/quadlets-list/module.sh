#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlets-list
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlets-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Lists Quadlet files for the podshift user as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F8A03C15D7B4:-}" ]]; then
    DIR_F8A03C15D7B4="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F8A03C15D7B4
fi

# shellcheck source=../../fn/quadlets/cockpit-quadlets-items.sh
declare -F cockpit-quadlets-items >/dev/null || source "${DIR_F8A03C15D7B4}/../../fn/quadlets/cockpit-quadlets-items.sh"

# @description: Runs podman, replaced in tests so the listing can be stubbed.
# @arg: $@ - podman arguments (quadlet ls --format json).
# @stdout: the JSON listing from podman.
# @exitcode: podman's exit code.
cockpit-quadlets-list-podman() {
    podman "$@"
}

# @description: Prints the quadlets-list result {items:[...]} for the podshift user.
# @details:
#   Runs `podman quadlet ls --format json` rootless in the podshift session. An empty or
#   null listing becomes {items:[]}. If podman fails, including a version that has no
#   `quadlet ls`, the action fails (exit 1).
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when podman or the mapping failed.
cockpit-module-quadlets-list() {
    local raw
    raw="$(cockpit-quadlets-list-podman quadlet ls --format json)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    cockpit-quadlets-items "${raw}"
}
