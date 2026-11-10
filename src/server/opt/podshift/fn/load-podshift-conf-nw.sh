#!/usr/bin/env bash
# @file: load-podshift-conf-nw.sh
# @source-dir: src/server/opt/podshift/fn
# @dest-dir: /opt/podshift/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Derives and exports the host's external IPv4 addresses.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Derives and exports TSV_NW1..8.
# @exitcode: 0 always.
load-podshift-conf-nw() {
    local initializer device_name conn_name ips line n i

    # shellcheck source=./load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source /opt/podshift/fn/load-podshift-conf-runtime.sh
    load-podshift-conf-runtime
    # shellcheck source=./network/nw-connection.sh
    declare -F nw-connection >/dev/null || source /opt/podshift/fn/network/nw-connection.sh
    # shellcheck source=./network/nw-config-ips.sh
    declare -F nw-config-ips >/dev/null || source /opt/podshift/fn/network/nw-config-ips.sh
    # shellcheck source=./network/nw-ips.sh
    declare -F nw-ips >/dev/null || source /opt/podshift/fn/network/nw-ips.sh

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
