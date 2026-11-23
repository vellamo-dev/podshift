#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Containers list module: lists the podshift user's Podman containers as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7C2E91A4D05B:-}" ]]; then
    DIR_7C2E91A4D05B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7C2E91A4D05B
fi

# @description: Lists the podshift user's Podman containers as resource cards.
# @details:
#   Reads podman ps -a, one batched podman container inspect and one podman stats sample of the
#   running containers, then finds which containers a Quadlet .container file
#   or another systemd unit runs. The items are built by cockpit-containers-items. The process runs
#   in the podshift session, so podman and systemctl --user already talk to that user.
#   The steps share an 8 second budget, 2 seconds under the 10 second module limit: the stats
#   sample gets the time that is left, at most 5 seconds, and is skipped when less than 1 second is
#   left, so a slow podman only leaves CPU and Memory out.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-containers-list() {
    local ps inspect quadlets units stats
    local -r budget=8
    local start
    start="${SECONDS}"
    # shellcheck source=./fn/cockpit-containers-list-ps.sh
    declare -F cockpit-containers-list-ps >/dev/null || source "${DIR_7C2E91A4D05B}/fn/cockpit-containers-list-ps.sh"
    # shellcheck source=./fn/cockpit-containers-list-inspect.sh
    declare -F cockpit-containers-list-inspect >/dev/null || source "${DIR_7C2E91A4D05B}/fn/cockpit-containers-list-inspect.sh"
    # shellcheck source=./fn/cockpit-containers-list-quadlets.sh
    declare -F cockpit-containers-list-quadlets >/dev/null || source "${DIR_7C2E91A4D05B}/fn/cockpit-containers-list-quadlets.sh"
    # shellcheck source=./fn/cockpit-containers-list-units.sh
    declare -F cockpit-containers-list-units >/dev/null || source "${DIR_7C2E91A4D05B}/fn/cockpit-containers-list-units.sh"
    # shellcheck source=./fn/cockpit-containers-list-usage.sh
    declare -F cockpit-containers-list-usage >/dev/null || source "${DIR_7C2E91A4D05B}/fn/cockpit-containers-list-usage.sh"
    # shellcheck source=../../fn/resources/cockpit-containers-items.sh
    declare -F cockpit-containers-items >/dev/null || source "${DIR_7C2E91A4D05B}/../../fn/resources/cockpit-containers-items.sh"
    ps="$(cockpit-containers-list-ps)" || return 1
    inspect="$(cockpit-containers-list-inspect "${ps}")" || return 1
    quadlets="$(cockpit-containers-list-quadlets)" || return 1
    units="$(cockpit-containers-list-units "${ps}")" || return 1
    stats="$(cockpit-containers-list-usage "${ps}" "$((budget - (SECONDS - start)))")"
    cockpit-containers-items "${ps}" "${inspect}" "${quadlets}" "${units}" "${stats}" "${HOME:-}"
}
