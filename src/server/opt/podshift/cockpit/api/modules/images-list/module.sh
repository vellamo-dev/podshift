#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/images-list
# @dest-dir: /opt/podshift/cockpit/api/modules/images-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Images list module: lists the podshift user's Podman images as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1D7066C59B4E:-}" ]]; then
    DIR_1D7066C59B4E="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1D7066C59B4E
fi

# @description: Lists the podshift user's Podman images as resource cards.
# @details:
#   Reads podman image ls, podman image inspect and podman ps -a, then finds which images come
#   from a Quadlet .image file and which are used by a container with a systemd unit. The items
#   are built by cockpit-images-items. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-images-list() {
    local images ctrs sources units
    # shellcheck source=./fn/cockpit-images-list-inspect.sh
    declare -F cockpit-images-list-inspect >/dev/null || source "${DIR_1D7066C59B4E}/fn/cockpit-images-list-inspect.sh"
    # shellcheck source=./fn/cockpit-images-list-containers.sh
    declare -F cockpit-images-list-containers >/dev/null || source "${DIR_1D7066C59B4E}/fn/cockpit-images-list-containers.sh"
    # shellcheck source=./fn/cockpit-images-list-sources.sh
    declare -F cockpit-images-list-sources >/dev/null || source "${DIR_1D7066C59B4E}/fn/cockpit-images-list-sources.sh"
    # shellcheck source=./fn/cockpit-images-list-units.sh
    declare -F cockpit-images-list-units >/dev/null || source "${DIR_1D7066C59B4E}/fn/cockpit-images-list-units.sh"
    # shellcheck source=../../fn/resources/cockpit-images-items.sh
    declare -F cockpit-images-items >/dev/null || source "${DIR_1D7066C59B4E}/../../fn/resources/cockpit-images-items.sh"
    images="$(cockpit-images-list-inspect)" || return 1
    [[ -n "${images}" ]] || images='[]'
    ctrs="$(cockpit-images-list-containers)" || return 1
    sources="$(cockpit-images-list-sources)" || return 1
    units="$(cockpit-images-list-units "${ctrs}")" || return 1
    cockpit-images-items "${images}" "${ctrs}" "${sources}" "${units}"
}
