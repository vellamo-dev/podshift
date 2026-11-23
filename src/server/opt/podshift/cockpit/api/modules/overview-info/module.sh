#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Overview info module: lists the OS, Podman, PodShift and Fail2Ban versions and the install type.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E6A30C49D1F2:-}" ]]; then
    DIR_E6A30C49D1F2="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E6A30C49D1F2
fi

# @description: Lists the OS, Podman, PodShift and Fail2Ban versions and the install type.
# @details:
#   The OS name comes from PRETTY_NAME in /etc/os-release. A missing package or file
#   becomes a null value. The install type is desktop or server.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-info() {
    local values text
    # shellcheck source=./fn/cockpit-overview-info-os-release.sh
    declare -F cockpit-overview-info-os-release >/dev/null || source "${DIR_E6A30C49D1F2}/fn/cockpit-overview-info-os-release.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-os-name.sh
    declare -F cockpit-overview-os-name >/dev/null || source "${DIR_E6A30C49D1F2}/../../fn/overview/cockpit-overview-os-name.sh"
    # shellcheck source=./fn/cockpit-overview-info-podman-version.sh
    declare -F cockpit-overview-info-podman-version >/dev/null || source "${DIR_E6A30C49D1F2}/fn/cockpit-overview-info-podman-version.sh"
    # shellcheck source=./fn/cockpit-overview-info-podshift-version.sh
    declare -F cockpit-overview-info-podshift-version >/dev/null || source "${DIR_E6A30C49D1F2}/fn/cockpit-overview-info-podshift-version.sh"
    # shellcheck source=./fn/cockpit-overview-info-fail2ban-version.sh
    declare -F cockpit-overview-info-fail2ban-version >/dev/null || source "${DIR_E6A30C49D1F2}/fn/cockpit-overview-info-fail2ban-version.sh"
    # shellcheck source=./fn/cockpit-overview-info-install-type.sh
    declare -F cockpit-overview-info-install-type >/dev/null || source "${DIR_E6A30C49D1F2}/fn/cockpit-overview-info-install-type.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-info-rows.sh
    declare -F cockpit-overview-info-rows >/dev/null || source "${DIR_E6A30C49D1F2}/../../fn/overview/cockpit-overview-info-rows.sh"
    values="{}"
    _overview_info_put() {
        local id text
        id="${1}"
        text="${2-}"
        if [[ -n "${text}" ]]; then
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" --arg value "${text}" '$values + {($id): $value}')" || return 1
        else
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" '$values + {($id): null}')" || return 1
        fi
    }
    text="$(cockpit-overview-os-name "$(cockpit-overview-info-os-release)")" || text=""
    _overview_info_put os "${text}" || return 1
    text="$(cockpit-overview-info-podman-version)"
    _overview_info_put podman "${text}" || return 1
    text="$(cockpit-overview-info-podshift-version)"
    _overview_info_put podshift "${text}" || return 1
    text="$(cockpit-overview-info-fail2ban-version)"
    _overview_info_put fail2ban "${text}" || return 1
    text="$(cockpit-overview-info-install-type)"
    _overview_info_put install "${text}" || return 1
    cockpit-overview-info-rows "${values}"
}
