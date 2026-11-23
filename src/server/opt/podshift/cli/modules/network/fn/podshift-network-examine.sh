#!/usr/bin/env bash
# @file: podshift-network-examine.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Detects and prints the external network facts and advice.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8271FCDF1A05:-}" ]]; then
    DIR_8271FCDF1A05="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8271FCDF1A05
fi

# @description: Detects and prints the external network facts and advice.
podshift-network-examine() {
    local backend device gateway connection mode ips line n
    if [[ "${1:-}" == "--json" ]]; then
        # shellcheck source=./podshift-network-examine-json.sh
        declare -F podshift-network-examine-json >/dev/null || source "${DIR_8271FCDF1A05}/podshift-network-examine-json.sh"
        podshift-network-examine-json
        return
    fi
    # shellcheck source=../../../../fn/network/nw-backend.sh
    declare -F nw-backend >/dev/null || source "${DIR_8271FCDF1A05}/../../../../fn/network/nw-backend.sh"
    # shellcheck source=../../../../fn/network/nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_8271FCDF1A05}/../../../../fn/network/nw-device.sh"
    # shellcheck source=../../../../fn/network/nw-gateway.sh
    declare -F nw-gateway >/dev/null || source "${DIR_8271FCDF1A05}/../../../../fn/network/nw-gateway.sh"
    # shellcheck source=../../../../fn/network/nw-connection.sh
    declare -F nw-connection >/dev/null || source "${DIR_8271FCDF1A05}/../../../../fn/network/nw-connection.sh"
    # shellcheck source=../../../../fn/network/nw-mode.sh
    declare -F nw-mode >/dev/null || source "${DIR_8271FCDF1A05}/../../../../fn/network/nw-mode.sh"
    # shellcheck source=../../../../fn/network/nw-ips.sh
    declare -F nw-ips >/dev/null || source "${DIR_8271FCDF1A05}/../../../../fn/network/nw-ips.sh"

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    connection="$(nw-connection)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"

    echo "Network"
    echo "  Backend    ${backend}"
    [[ -n "${connection}" ]] && echo "  Connection ${connection}"
    echo "  Device     ${device:-none}"
    echo "  Gateway    ${gateway:-none}"
    case "${mode}" in
        manual) echo "  Mode       manual (static)" ;;
        auto)   echo "  Mode       auto (DHCP)" ;;
        *)      echo "  Mode       ${mode}" ;;
    esac
    if [[ -n "${ips}" ]]; then
        n=1
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            echo "  TSV_NW${n}    ${line}"
            n=$((n + 1))
        done <<<"${ips}"
    else
        echo "  IPs        none detected"
    fi

    echo
    echo "Notes"
    case "${mode}" in
        auto)
            echo "  * Mode is DHCP - the IP may change on reboot. To pin it:"
            echo "      nmcli connection modify ${connection} ipv4.method manual ipv4.addresses <ip>/24 ipv4.gateway ${gateway}"
            echo "      nmcli connection up ${connection}"
            ;;
        manual)
            echo "  * Static configuration - the IPs are stable."
            ;;
        *)
            echo "  * Could not determine the active connection or its IP method."
            ;;
    esac
    if [[ -z "${device}" ]]; then
        echo "  * No default route found - the machine may have no internet path."
    fi
}
