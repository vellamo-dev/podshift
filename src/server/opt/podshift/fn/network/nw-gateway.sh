#!/usr/bin/env bash
# @file: nw-gateway.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the default-route gateway.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the default-route gateway.
# @stdout: the gateway address, empty when there is no default route.
nw-gateway() {
    ip route show default 2>/dev/null | awk 'NR==1{print $3}'
}
