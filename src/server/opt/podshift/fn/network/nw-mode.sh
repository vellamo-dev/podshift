#!/usr/bin/env bash
# @file: nw-mode.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the IPv4 method of the active connection.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C6A00C03503D:-}" ]]; then
    DIR_C6A00C03503D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C6A00C03503D
fi

# @description: Prints the IPv4 method of the active connection.
# @stdout: manual, auto, or unknown.
nw-mode() {
    local conn method
    # shellcheck source=./nw-connection.sh
    declare -F nw-connection >/dev/null || source "${DIR_C6A00C03503D}/nw-connection.sh"
    conn="$(nw-connection)"
    [[ -n "${conn}" ]] || { echo "unknown"; return; }
    method="$(nmcli -t -f ipv4.method connection show "${conn}" 2>/dev/null | cut -d: -f2-)"
    echo "${method:-unknown}"
}
