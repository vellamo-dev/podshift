#!/usr/bin/env bash
# @file: podshift-network-fix.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Detects network problems and interactively repairs the configuration.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_902E18331DFD:-}" ]]; then
    DIR_902E18331DFD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_902E18331DFD
fi

# @description: Detects network problems and interactively repairs the configuration.
# @exitcode: 0 on success.
podshift-network-fix() {
    local backend device gateway mode ips
    local current_device current_initializer did_fix d
    local -a ip_devices
    # shellcheck source=../../../../fn/network/nw-backend.sh
    declare -F nw-backend >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/nw-backend.sh"
    # shellcheck source=../../../../fn/network/nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/nw-device.sh"
    # shellcheck source=../../../../fn/network/nw-gateway.sh
    declare -F nw-gateway >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/nw-gateway.sh"
    # shellcheck source=../../../../fn/network/nw-mode.sh
    declare -F nw-mode >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/nw-mode.sh"
    # shellcheck source=../../../../fn/network/nw-ips.sh
    declare -F nw-ips >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/nw-ips.sh"
    # shellcheck source=../../../../fn/load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"
    current_device="${PODSHIFT_NW_DEVICE:-}"
    current_initializer="${PODSHIFT_NW_INITIALIZER:-}"
    did_fix=0

    echo "Network fix"
    echo "Note: fix only repairs PodShift's configuration (device and initializer). It does not change the system's network."
    echo

    echo "Configuration:"
    echo "  Initializer  ${current_initializer:-auto-detect}"
    echo "  Device       ${current_device:-auto-detect}"
    echo

    # Non-fixable system issues: warn and advise.
    [[ -z "${gateway}" ]] && echo "  No default route    a system issue; fix cannot repair this."
    [[ -z "${ips}" ]]      && echo "  No external IP      a system issue; fix cannot repair this."
    [[ "${mode}" == "auto" ]] && echo "  DHCP mode           a system setting; fix cannot change this."

    # Fixable: the initializer is missing or wrong.
    if [[ -z "${current_initializer}" ]]; then
        # shellcheck source=../../../../fn/network/is-cloud-init-present.sh
        declare -F is-cloud-init-present >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/is-cloud-init-present.sh"
        if is-cloud-init-present; then
            echo
            echo "cloud-init is present but no initializer is configured."
            # shellcheck source=./podshift-network-set-initializer-menu.sh
            declare -F podshift-network-set-initializer-menu >/dev/null || source "${DIR_902E18331DFD}/podshift-network-set-initializer-menu.sh"
            podshift-network-set-initializer-menu
            did_fix=1
        fi
    else
        # shellcheck source=./podshift-network-set-validate.sh
        declare -F podshift-network-set-validate >/dev/null || source "${DIR_902E18331DFD}/podshift-network-set-validate.sh"
        if ! podshift-network-set-validate "PODSHIFT_NW_INITIALIZER" "${current_initializer}"; then
            echo
            echo "The configured initializer '${current_initializer}' is not detected on this system."
            # shellcheck source=./podshift-network-set-initializer-menu.sh
            declare -F podshift-network-set-initializer-menu >/dev/null || source "${DIR_902E18331DFD}/podshift-network-set-initializer-menu.sh"
            podshift-network-set-initializer-menu
            did_fix=1
        fi
    fi

    # Fixable: the configured device does not exist.
    if [[ -n "${current_device}" && ! -d "/sys/class/net/${current_device}" ]]; then
        echo
        echo "The configured device '${current_device}' does not exist (detected: ${device})."
        # shellcheck source=./podshift-network-set-device-menu.sh
        declare -F podshift-network-set-device-menu >/dev/null || source "${DIR_902E18331DFD}/podshift-network-set-device-menu.sh"
        podshift-network-set-device-menu
        did_fix=1
    fi

    # Fixable: several devices carry an IP address, so the main one is ambiguous.
    # shellcheck source=../../../../fn/network/nw-list-devices.sh
    declare -F nw-list-devices >/dev/null || source "${DIR_902E18331DFD}/../../../../fn/network/nw-list-devices.sh"
    while IFS= read -r d; do
        [[ -n "$(ip -4 -o addr show dev "${d}" 2>/dev/null)" ]] && ip_devices+=("${d}")
    done < <(nw-list-devices)
    if (( ${#ip_devices[@]} > 1 )); then
        echo
        echo "Several devices carry an IP address (${ip_devices[*]}); the main one is ambiguous."
        # shellcheck source=./podshift-network-set-device-menu.sh
        declare -F podshift-network-set-device-menu >/dev/null || source "${DIR_902E18331DFD}/podshift-network-set-device-menu.sh"
        podshift-network-set-device-menu
        did_fix=1
    fi

    if [[ "${did_fix}" -eq 1 ]]; then
        echo
        echo "Resulting state:"
        # shellcheck source=./podshift-network-print.sh
        declare -F podshift-network-print >/dev/null || source "${DIR_902E18331DFD}/podshift-network-print.sh"
        podshift-network-print
    else
        echo
        echo "Nothing to fix in the configuration. Run 'podshift nw check' for the full health check."
    fi
    echo
    echo "Done."
    return 0
}
