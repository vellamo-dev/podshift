#!/usr/bin/env bash
# @file: nw-connection.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the active NetworkManager connection name.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the active NetworkManager connection name.
# @stdout: the connection name (e.g. HappyMac5G), empty when none.
nw-connection() {
    nmcli -t -f NAME connection show --active 2>/dev/null | grep -v '^lo$' | head -n1
}
