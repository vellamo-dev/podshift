#!/usr/bin/env bash
# @file: 100-os.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: OS
# @run-as: any
# @description: Identifies the OS and whether it is a supported Fedora release.
# @rationale: The checks only give meaningful results on the supported Fedora target.
# @fix: Run PodShift on a supported Fedora release.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the os check.
# @stdout: one TSV line: os<TAB><status><TAB><detail>.
# @exitcode: 0 = supported, 1 = unsupported platform.

health-check-os() {
    local kern id ver name min
    min="${PODSHIFT_MIN_FEDORA:-45}"
    kern="$(uname -s 2>/dev/null)"
    if [[ "${kern}" == "Darwin" ]]; then
        name="macOS $(sw_vers -productVersion 2>/dev/null)"
        id="darwin"
        ver=""
    else
        id="$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
        ver="$(grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
        name="$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
        [[ -n "${name}" ]] || name="${id} ${ver}"
    fi
    if [[ "${id}" == "fedora" && -n "${ver}" && "${ver}" -ge "${min}" ]]; then
        printf 'os\tOK\t%s\n' "${name:-unknown}"
        return 0
    fi
    printf 'os\tWARN\t%s (unsupported, expected Fedora %s+)\n' "${name:-unknown}" "${min}"
    return 1
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-os
