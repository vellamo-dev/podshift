#!/usr/bin/env bash
# @file: get-host-info.sh
# @source-dir: src/server/opt/podshift/fn/common
# @dest-dir: /opt/podshift/fn/common
# @host-edit: no
# @group: common
# @category: helper
# @description: Prints a one-line description of the host.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C4D8E2F6A9B7:-}" ]]; then
    DIR_C4D8E2F6A9B7="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C4D8E2F6A9B7
fi

# @description: Prints the host as one line: distro, variant, type, kernel and architecture.
# @details:
#   When /etc/os-release is missing it prints the kernel name and architecture only.
# @stdout: the host description.
# @exitcode: 0 always.
get-host-info() {
    local kernel_release kernel_arch distro_id distro_type distro_version distro_variant line
    kernel_release="$(uname -r)"
    kernel_arch="$(uname -m)"
    if [[ -r /etc/os-release ]]; then
        distro_id="$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
        distro_type="$(grep '^RELEASE_TYPE=' /etc/os-release | cut -d= -f2 | tr -d '"')"
        # shellcheck source=../utils/get-fedora-version.sh
        declare -F get-fedora-version >/dev/null || source "${DIR_C4D8E2F6A9B7}/../utils/get-fedora-version.sh"
        distro_version="$(get-fedora-version)"
        distro_variant="$(grep '^VARIANT=' /etc/os-release | cut -d= -f2 | tr -d '"')"
        line="${distro_id} ${distro_version}"
        [[ -n "${distro_variant}" ]] && line+=" ${distro_variant}"
        printf '%s (%s, %s-%s)\n' "${line}" "${distro_type}" "${kernel_release}" "${kernel_arch}"
    else
        printf '%s (%s-%s)\n' "$(uname -s)" "${kernel_release}" "${kernel_arch}"
    fi
    return 0
}
