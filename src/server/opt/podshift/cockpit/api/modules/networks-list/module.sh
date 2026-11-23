#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Networks list module: lists the podshift user's Podman networks as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4C8A1E6F2B93:-}" ]]; then
    DIR_4C8A1E6F2B93="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4C8A1E6F2B93
fi

# @description: Lists the podshift user's Podman networks as resource cards.
# @details:
#   Reads podman network ls and podman network inspect, then finds which networks come from a
#   Quadlet .network file or a user service with podman network create. The items are built by
#   cockpit-networks-items. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-networks-list() {
    local nets sources
    # shellcheck source=./fn/cockpit-networks-list-inspect.sh
    declare -F cockpit-networks-list-inspect >/dev/null || source "${DIR_4C8A1E6F2B93}/fn/cockpit-networks-list-inspect.sh"
    # shellcheck source=./fn/cockpit-networks-list-sources.sh
    declare -F cockpit-networks-list-sources >/dev/null || source "${DIR_4C8A1E6F2B93}/fn/cockpit-networks-list-sources.sh"
    # shellcheck source=../../fn/resources/cockpit-networks-items.sh
    declare -F cockpit-networks-items >/dev/null || source "${DIR_4C8A1E6F2B93}/../../fn/resources/cockpit-networks-items.sh"
    nets="$(cockpit-networks-list-inspect)" || return 1
    [[ -n "${nets}" ]] || nets='[]'
    sources="$(cockpit-networks-list-sources)" || return 1
    cockpit-networks-items "${nets}" "${sources}"
}
