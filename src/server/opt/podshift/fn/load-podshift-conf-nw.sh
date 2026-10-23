#!/usr/bin/env bash
# @file: load-podshift-conf-nw.sh
# @dir: /opt/podshift/fn
# @group: network
# @description: Derives and exports the host's external IPv4 addresses.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Derives and exports TSV_NW1..8.
# @exitcode: 0 always.
podshift-conf-nw() {
    local initializer device_name conn_name ips line n i

    # shellcheck source=../load-podshift-conf-runtime.sh
    source /opt/podshift/fn/load-podshift-conf-runtime.sh --now
    # shellcheck source=network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh

    initializer="${PODSHIFT_NW_INITIALIZER:-}"
    device_name="${PODSHIFT_NW_DEVICE:-}"

    # Resolve the connection name: override first, then auto-detect.
    if [[ -n "${initializer}" && -n "${device_name}" ]]; then
        conn_name="${initializer}-${device_name}"
    else
        conn_name="$(nw-connection)"
    fi

    # Read the ordered manual conf; fall back to the profile/live view when absent.
    ips="$(nw-config-ips "${conn_name}" 2>/dev/null)"
    [[ -n "${ips}" ]] || ips="$(nw-ips)"

    # Export TSV_NW1..8.
    n=1
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        [[ ${n} -le 8 ]] || break
        export "TSV_NW${n}=${line}"
        n=$((n + 1))
    done <<<"${ips}"
    for (( i = n; i <= 8; i++ )); do
        unset "TSV_NW${i}"
    done
}

# @description: Prints the defined TSV_NW* environment variables.
# @stdout: prints the defined TSV_NW* variables.
podshift-conf-nw-print() {
    local i var_name var_value
    echo -e "\nSystem has the following IPv4s defined:\n"
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        [[ -n "${var_value}" ]] && echo "  ${var_name}=${var_value}"
    done
    echo ""
}

# Executes only when called or sourced with --print or --now
case "${1:-}" in
    --print) podshift-conf-nw; podshift-conf-nw-print ;;
    --now)   podshift-conf-nw ;;
esac
