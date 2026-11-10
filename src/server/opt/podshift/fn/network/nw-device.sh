#!/usr/bin/env bash
# @file: nw-device.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the default-route device.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the default-route device.
# @stdout: the device name (e.g. enp0s1), empty when there is no default route.
nw-device() {
    ip route show default 2>/dev/null | awk 'NR==1{print $5}'
}
