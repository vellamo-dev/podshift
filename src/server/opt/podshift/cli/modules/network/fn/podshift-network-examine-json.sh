#!/usr/bin/env bash
# @file: podshift-network-examine-json.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the examine facts as a single line of JSON.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5CBFCB692E9B:-}" ]]; then
    DIR_5CBFCB692E9B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5CBFCB692E9B
fi

# @description: Prints the examine facts as a single line of JSON.
# @stdout: one line of JSON.
podshift-network-examine-json() {
    local backend device gateway connection mode ips line n
    # shellcheck source=../../../../fn/network/nw-backend.sh
    declare -F nw-backend >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/network/nw-backend.sh"
    # shellcheck source=../../../../fn/network/nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/network/nw-device.sh"
    # shellcheck source=../../../../fn/network/nw-gateway.sh
    declare -F nw-gateway >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/network/nw-gateway.sh"
    # shellcheck source=../../../../fn/network/nw-connection.sh
    declare -F nw-connection >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/network/nw-connection.sh"
    # shellcheck source=../../../../fn/network/nw-mode.sh
    declare -F nw-mode >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/network/nw-mode.sh"
    # shellcheck source=../../../../fn/network/nw-ips.sh
    declare -F nw-ips >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/network/nw-ips.sh"
    # shellcheck source=../../../../fn/utils/json-q.sh
    declare -F json-q >/dev/null || source "${DIR_5CBFCB692E9B}/../../../../fn/utils/json-q.sh"

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    connection="$(nw-connection)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"

    printf '{'
    printf '"backend":%s' "$(json-q "${backend}")"
    printf ',"connection":%s' "$(json-q "${connection}")"
    printf ',"device":%s' "$(json-q "${device}")"
    printf ',"gateway":%s' "$(json-q "${gateway}")"
    printf ',"mode":%s' "$(json-q "${mode}")"
    printf ',"ips":['
    n=0
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        [[ ${n} -gt 0 ]] && printf ','
        printf '%s' "$(json-q "${line}")"
        n=$((n + 1))
    done <<<"${ips}"
    printf ']}'
    printf '\n'
}
