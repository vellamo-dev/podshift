#!/usr/bin/env bash
# @file: nw-list-devices.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Lists the network devices of the host, without the loopback device.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the network devices in /sys/class/net, one per line, without lo.
# @stdout: one device name per line, empty when there is none.
# @exitcode: 0 always.
nw-list-devices() {
    local dev
    while IFS= read -r dev; do
        [[ -n "${dev}" && "${dev}" != "lo" ]] && echo "${dev}"
    done < <(ls /sys/class/net/ 2>/dev/null)
    return 0
}
