#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Overview usage module: lists counts for user services, Podman objects and installed Quadlets.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D5F29B38C0E1:-}" ]]; then
    DIR_D5F29B38C0E1="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D5F29B38C0E1
fi

# @description: Lists usage counts for services, networks, containers, volumes, images, Quadlets and secrets.
# @details:
#   Services are the podshift user's loaded systemd user service units, as active over
#   total, from systemctl --user list-units --type=service --all. Units whose load state
#   is not loaded (not-found, masked or error) are omitted. A total of 0 is shown as 0.
#   Containers are running over all. Images and volumes are unique objects used by any
#   container, over the objects listed by podman. Networks, Quadlets and secrets are
#   totals only: podman network ls, installed Quadlet files in PODSHIFT_PODMAN_QUADLETS_DIR,
#   and podman secret ls. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-usage() {
    local values text
    # shellcheck source=./fn/cockpit-overview-usage-service-counts.sh
    declare -F cockpit-overview-usage-service-counts >/dev/null || source "${DIR_D5F29B38C0E1}/fn/cockpit-overview-usage-service-counts.sh"
    # shellcheck source=./fn/cockpit-overview-usage-podman-counts.sh
    declare -F cockpit-overview-usage-podman-counts >/dev/null || source "${DIR_D5F29B38C0E1}/fn/cockpit-overview-usage-podman-counts.sh"
    # shellcheck source=./fn/cockpit-overview-usage-quadlet-counts.sh
    declare -F cockpit-overview-usage-quadlet-counts >/dev/null || source "${DIR_D5F29B38C0E1}/fn/cockpit-overview-usage-quadlet-counts.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-usage-rows.sh
    declare -F cockpit-overview-usage-rows >/dev/null || source "${DIR_D5F29B38C0E1}/../../fn/overview/cockpit-overview-usage-rows.sh"
    values="{}"
    _overview_usage_put() {
        local id text
        id="${1}"
        text="${2-}"
        if [[ -n "${text}" ]]; then
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" --arg value "${text}" '$values + {($id): $value}')" || return 1
        else
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" '$values + {($id): null}')" || return 1
        fi
    }
    text="$(cockpit-overview-usage-service-counts)"
    _overview_usage_put services "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts networks)"
    _overview_usage_put networks "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts containers)"
    _overview_usage_put containers "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts volumes)"
    _overview_usage_put volumes "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts images)"
    _overview_usage_put images "${text}" || return 1
    text="$(cockpit-overview-usage-quadlet-counts all)"
    _overview_usage_put quadlets "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts secrets)"
    _overview_usage_put secrets "${text}" || return 1
    cockpit-overview-usage-rows "${values}"
}
