#!/usr/bin/env bash
# @file: podshift-network-set.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Lists devices or sets the network override.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E6D07DAE7541:-}" ]]; then
    DIR_E6D07DAE7541="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E6D07DAE7541
fi

# @description: Lists devices or sets the network override.
# @arg: $@ - [--device <device>] [--initializer <initializer>] [--force].
podshift-network-set() {
    local key value force known
    key=""
    value=""
    force=0
    known=1

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --device)      key="PODSHIFT_NW_DEVICE";      value="${2:-}"; [[ -n "${2:-}" ]] && shift ;;
            --initializer) key="PODSHIFT_NW_INITIALIZER"; value="${2:-}"; [[ -n "${2:-}" ]] && shift ;;
            --force)       force=1 ;;
            *) echo "Unknown option: ${1}" >&2; return 1 ;;
        esac
        shift
    done

    if [[ -z "${key}" ]]; then
        # shellcheck source=./podshift-network-set-device-menu.sh
        declare -F podshift-network-set-device-menu >/dev/null || source "${DIR_E6D07DAE7541}/podshift-network-set-device-menu.sh"
        podshift-network-set-device-menu
        return
    fi

    if [[ -z "${value}" ]]; then
        case "${key}" in
            PODSHIFT_NW_DEVICE)
                # shellcheck source=./podshift-network-set-device-menu.sh
                declare -F podshift-network-set-device-menu >/dev/null || source "${DIR_E6D07DAE7541}/podshift-network-set-device-menu.sh"
                podshift-network-set-device-menu
                ;;
            PODSHIFT_NW_INITIALIZER)
                # shellcheck source=./podshift-network-set-initializer-menu.sh
                declare -F podshift-network-set-initializer-menu >/dev/null || source "${DIR_E6D07DAE7541}/podshift-network-set-initializer-menu.sh"
                podshift-network-set-initializer-menu
                ;;
        esac
        return
    fi

    known=1
    # shellcheck source=./podshift-network-set-validate.sh
    declare -F podshift-network-set-validate >/dev/null || source "${DIR_E6D07DAE7541}/podshift-network-set-validate.sh"
    podshift-network-set-validate "${key}" "${value}" || known=0
    # shellcheck source=./podshift-network-set-write.sh
    declare -F podshift-network-set-write >/dev/null || source "${DIR_E6D07DAE7541}/podshift-network-set-write.sh"
    podshift-network-set-write "${key}" "${value}" "${force}" "${known}"
}
