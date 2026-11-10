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
# @stdout: the IPs; config addresses when manual, the live system when auto.
nw-ips() {
    local dev mode conn
    # shellcheck source=./nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_24B66A1D2622}/nw-device.sh"
    # shellcheck source=./nw-mode.sh
    declare -F nw-mode >/dev/null || source "${DIR_24B66A1D2622}/nw-mode.sh"
    # shellcheck source=./nw-connection.sh
    declare -F nw-connection >/dev/null || source "${DIR_24B66A1D2622}/nw-connection.sh"
    dev="$(nw-device)"
    mode="$(nw-mode)"
    if [[ "${mode}" == "manual" ]]; then
        conn="$(nw-connection)"
        nmcli -t -f ipv4.addresses connection show "${conn}" 2>/dev/null \
            | cut -d: -f2- \
            | tr ',' '\n' \
            | sed 's|/.*||; s|^ *||; s| *$||' \
            | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
    else
        [[ -n "${dev}" ]] || return 0
        ip -4 -o addr show scope global dev "${dev}" 2>/dev/null | awk '{print $4}' | cut -d/ -f1
    fi
}
