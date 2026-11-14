#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Overview info module: lists the OS, Podman, PodShift and Fail2Ban versions.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E6A30C49D1F2:-}" ]]; then
    DIR_E6A30C49D1F2="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E6A30C49D1F2
fi

# shellcheck source=../../fn/overview/cockpit-overview-os-name.sh
declare -F cockpit-overview-os-name >/dev/null || source "${DIR_E6A30C49D1F2}/../../fn/overview/cockpit-overview-os-name.sh"
# shellcheck source=../../fn/overview/cockpit-overview-info-rows.sh
declare -F cockpit-overview-info-rows >/dev/null || source "${DIR_E6A30C49D1F2}/../../fn/overview/cockpit-overview-info-rows.sh"

# @description: Prints the contents of /etc/os-release, if it can be read.
# @stdout: os-release text, or nothing.
# @exitcode: 0 always.
cockpit-overview-info-os-release() {
    cat /etc/os-release 2>/dev/null || true
}

# @description: Prints the installed Podman version.
# @stdout: a version string, or nothing when Podman is missing.
# @exitcode: 0 always.
cockpit-overview-info-podman-version() {
    local version
    version="$(podman version --format '{{.Client.Version}}' 2>/dev/null || true)"
    if [[ -z "${version}" ]]; then
        version="$(rpm -q --qf '%{VERSION}' podman 2>/dev/null || true)"
    fi
    case "${version}" in
        ''|*is\ not\ installed*)
            return 0
            ;;
    esac
    printf '%s\n' "${version}"
}

# @description: Prints the installed PodShift version.
# @stdout: a version string, or nothing when it cannot be read.
# @exitcode: 0 always.
cockpit-overview-info-podshift-version() {
    local version
    # shellcheck source=../../../../fn/common/get-podshift-version.sh
    declare -F get-podshift-version >/dev/null || source "${DIR_E6A30C49D1F2}/../../../../fn/common/get-podshift-version.sh"
    version="$(get-podshift-version 2>/dev/null || true)"
    [[ -n "${version}" ]] || return 0
    printf '%s\n' "${version}"
}

# @description: Prints the installed Fail2Ban version.
# @stdout: a version string, or nothing when Fail2Ban is missing.
# @exitcode: 0 always.
cockpit-overview-info-fail2ban-version() {
    local version
    version="$(rpm -q --qf '%{VERSION}' fail2ban 2>/dev/null || true)"
    if [[ -z "${version}" || "${version}" == *"is not installed"* ]]; then
        version="$(fail2ban-client version 2>/dev/null || true)"
    fi
    case "${version}" in
        ''|*is\ not\ installed*)
            return 0
            ;;
    esac
    version="${version#Fail2Ban }"
    version="${version#Fail2Ban v}"
    version="${version#v}"
    printf '%s\n' "${version}"
}

# @description: Lists the OS, Podman, PodShift and Fail2Ban versions.
# @details:
#   The OS name comes from PRETTY_NAME in /etc/os-release. A missing package or file
#   becomes a null value.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-info() {
    local values text
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
    cockpit-overview-info-rows "${values}"
}
