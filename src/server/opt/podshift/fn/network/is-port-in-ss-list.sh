#!/usr/bin/env bash
# @file: is-port-in-ss-list.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @unit-test: yes
# @description: Tells whether a TCP port is in the output of ss -tln.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 if a listening socket in the ss output has the given local port.
# @arg: $1 - the output of ss -tln.
# @arg: $2 - the port number, matched exactly (1022 does not match 10220).
# @exitcode: 0 if the port is listed, 1 otherwise.
is-port-in-ss-list() {
    local ss_output port state recv_q send_q local_address rest
    ss_output="${1:-}"
    port="${2:-}"
    [[ -n "${port}" ]] || return 1
    while read -r state recv_q send_q local_address rest; do
        [[ "${local_address}" == *":${port}" ]] && return 0
    done <<<"${ss_output}"
    return 1
}
