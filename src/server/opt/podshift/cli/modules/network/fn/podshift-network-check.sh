#!/usr/bin/env bash
# @file: podshift-network-check.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Runs the network health checks and prints a verdict.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_FA7348F9983C:-}" ]]; then
    DIR_FA7348F9983C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_FA7348F9983C
fi

# @description: Runs the network health checks and prints a verdict.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.
podshift-network-check() {
    local backend device gateway mode ips line rc
    local fail_count warn_count
    # shellcheck source=../../../../fn/network/nw-backend.sh
    declare -F nw-backend >/dev/null || source "${DIR_FA7348F9983C}/../../../../fn/network/nw-backend.sh"
    # shellcheck source=../../../../fn/network/nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_FA7348F9983C}/../../../../fn/network/nw-device.sh"
    # shellcheck source=../../../../fn/network/nw-gateway.sh
    declare -F nw-gateway >/dev/null || source "${DIR_FA7348F9983C}/../../../../fn/network/nw-gateway.sh"
    # shellcheck source=../../../../fn/network/nw-mode.sh
    declare -F nw-mode >/dev/null || source "${DIR_FA7348F9983C}/../../../../fn/network/nw-mode.sh"
    # shellcheck source=../../../../fn/network/nw-ips.sh
    declare -F nw-ips >/dev/null || source "${DIR_FA7348F9983C}/../../../../fn/network/nw-ips.sh"

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"

    fail_count=0
    warn_count=0

    echo "Network check"

    if [[ -n "${device}" ]]; then
        echo "  Default route   OK     ${device} via ${gateway}"
    else
        echo "  Default route   FAIL   no default route"
        fail_count=$((fail_count + 1))
    fi

    if [[ -n "${ips}" ]]; then
        line="$(printf '%s' "${ips}" | head -n1)"
        echo "  External IP     OK     ${line}"
    else
        echo "  External IP     FAIL   no external IPv4"
        fail_count=$((fail_count + 1))
    fi

    echo "  Outgoing"
    # shellcheck source=./podshift-network-check-outgoing.sh
    declare -F podshift-network-check-outgoing >/dev/null || source "${DIR_FA7348F9983C}/podshift-network-check-outgoing.sh"
    podshift-network-check-outgoing
    rc=$?
    case "${rc}" in
        1) warn_count=$((warn_count + 1)) ;;
        2) fail_count=$((fail_count + 1)) ;;
    esac

    if [[ "${backend}" != "none" ]]; then
        echo "  Backend         OK     ${backend}"
    else
        echo "  Backend         WARN   no network backend active"
        warn_count=$((warn_count + 1))
    fi

    case "${mode}" in
        auto)
            echo "  Mode            WARN   DHCP - IP may change on reboot"
            warn_count=$((warn_count + 1))
            ;;
        manual)
            echo "  Mode            OK     static"
            ;;
        *)
            echo "  Mode            WARN   ${mode}"
            warn_count=$((warn_count + 1))
            ;;
    esac

    echo
    if (( fail_count > 0 )); then
        echo "Result: FAIL (${fail_count} failure, ${warn_count} warning)"
        return 2
    elif (( warn_count > 0 )); then
        echo "Result: WARN (${warn_count} warning)"
        return 1
    else
        echo "Result: OK"
        return 0
    fi
}
