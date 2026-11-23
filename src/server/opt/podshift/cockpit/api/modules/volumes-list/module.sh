#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Volumes list module: lists the podshift user's Podman volumes as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_BFE741360D80:-}" ]]; then
    DIR_BFE741360D80="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_BFE741360D80
fi

# @description: Lists the podshift user's Podman volumes as resource cards.
# @details:
#   Reads podman volume ls, podman volume inspect, podman ps -a and podman container inspect,
#   measures the mountpoints with du in a shared 5 second budget, then finds which volumes come from a Quadlet .volume file
#   and which are mounted by a container with a systemd unit. The items are built by
#   cockpit-volumes-items. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-volumes-list() {
    local vols ctrs sources units sizes
    # shellcheck source=./fn/cockpit-volumes-list-inspect.sh
    declare -F cockpit-volumes-list-inspect >/dev/null || source "${DIR_BFE741360D80}/fn/cockpit-volumes-list-inspect.sh"
    # shellcheck source=./fn/cockpit-volumes-list-containers.sh
    declare -F cockpit-volumes-list-containers >/dev/null || source "${DIR_BFE741360D80}/fn/cockpit-volumes-list-containers.sh"
    # shellcheck source=./fn/cockpit-volumes-list-sources.sh
    declare -F cockpit-volumes-list-sources >/dev/null || source "${DIR_BFE741360D80}/fn/cockpit-volumes-list-sources.sh"
    # shellcheck source=./fn/cockpit-volumes-list-units.sh
    declare -F cockpit-volumes-list-units >/dev/null || source "${DIR_BFE741360D80}/fn/cockpit-volumes-list-units.sh"
    # shellcheck source=./fn/cockpit-volumes-list-sizes.sh
    declare -F cockpit-volumes-list-sizes >/dev/null || source "${DIR_BFE741360D80}/fn/cockpit-volumes-list-sizes.sh"
    # shellcheck source=../../fn/resources/cockpit-volumes-items.sh
    declare -F cockpit-volumes-items >/dev/null || source "${DIR_BFE741360D80}/../../fn/resources/cockpit-volumes-items.sh"
    vols="$(cockpit-volumes-list-inspect)" || return 1
    [[ -n "${vols}" ]] || vols='[]'
    ctrs="$(cockpit-volumes-list-containers)" || return 1
    sources="$(cockpit-volumes-list-sources)" || return 1
    units="$(cockpit-volumes-list-units "${ctrs}")" || return 1
    sizes="$(cockpit-volumes-list-sizes "${vols}")" || return 1
    cockpit-volumes-items "${vols}" "${ctrs}" "${sources}" "${units}" "${sizes}" "${HOME:-}"
}
