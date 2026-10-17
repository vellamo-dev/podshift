#!/usr/bin/env bash
# podshift-version.sh
# /usr/local/etc/podshift/fn/common

if [[ -z "${DIR_E55364727DBB:-}" ]]; then
    DIR_E55364727DBB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E55364727DBB
fi

# shellcheck source=../utils/get-fedora-version.sh
source "${DIR_E55364727DBB}/../utils/get-fedora-version.sh"
# shellcheck source=../utils/is-podshift-rpm-install.sh
source "${DIR_E55364727DBB}/../utils/is-podshift-rpm-install.sh"

podshift-version() {
    local installed=0 podshift_version distro_id distro_version distro_type distro_variant kernel_release kernel_arch
    local distro_line
    if is-podshift-rpm-install; then
        installed=1
        podshift_version="$(rpm -q podshift --qf '%{VERSION}' 2>/dev/null)"
    else
        podshift_version="0.0.0-local-dev"
    fi
    echo -e "PodShift v${podshift_version}"
    kernel_release=$(uname -r)
    kernel_arch=$(uname -m)
    if [[ -r /etc/os-release ]]; then
        distro_id=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
        distro_type=$(grep '^RELEASE_TYPE=' /etc/os-release | cut -d= -f2 | tr -d '"')
        distro_version="$(get-fedora-version)"
        distro_variant=$(grep '^VARIANT=' /etc/os-release | cut -d= -f2 | tr -d '"')
        distro_line="${distro_id} ${distro_version}"
        [[ -n "${distro_variant}" ]] && distro_line+=" ${distro_variant}"
        echo -e "${distro_line} (${distro_type}, ${kernel_release}-${kernel_arch})"
    else
        echo -e "$(uname -s) (${kernel_release}-${kernel_arch})"
    fi
    if [[ "${installed}" -eq 0 ]]; then
        echo -e "\033[1;33mWarning: this is development code, not a working application.\033[0m" >&2
    fi
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && podshift-version
fi
