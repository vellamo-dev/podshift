#!/usr/bin/env bash
# @file: nw-ips.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the external IPv4 addresses, one per line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_24B66A1D2622:-}" ]]; then
    DIR_24B66A1D2622="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_24B66A1D2622
fi

# @description: Prints the external IPv4 addresses, one per line.
# @details:
#   One nmcli call reads both the IPv4 method and the addresses of the connection.
# @arg: $1 - connection name, already detected by the caller; empty or missing detects it here.
# @stdout: the IPs; config addresses when manual, the live system when auto.
nw-ips() {
    local dev conn fields method
    # shellcheck source=./nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_24B66A1D2622}/nw-device.sh"
    # shellcheck source=./nw-connection.sh
    declare -F nw-connection >/dev/null || source "${DIR_24B66A1D2622}/nw-connection.sh"
    conn="${1:-}"
    [[ -n "${conn}" ]] || conn="$(nw-connection)"
    fields=""
    [[ -z "${conn}" ]] || fields="$(nmcli -t -f ipv4.method,ipv4.addresses connection show "${conn}" 2>/dev/null)"
    method="$(sed -n 's/^ipv4\.method://p' <<<"${fields}")"
    if [[ "${method}" == "manual" ]]; then
        sed -n 's/^ipv4\.addresses://p' <<<"${fields}" \
            | tr ',' '\n' \
            | sed 's|/.*||; s|^ *||; s| *$||' \
            | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
    else
        dev="$(nw-device)"
        [[ -n "${dev}" ]] || return 0
        ip -4 -o addr show scope global dev "${dev}" 2>/dev/null | awk '{print $4}' | cut -d/ -f1
    fi
}
