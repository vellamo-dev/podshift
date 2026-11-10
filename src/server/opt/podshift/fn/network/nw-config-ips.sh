#!/usr/bin/env bash
# @file: nw-config-ips.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Reads the ordered IPv4 addresses from a NetworkManager config file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads the ordered IPv4 addresses from a NetworkManager config file.
# @arg: $1 - connection name (e.g. cloud-init-eth0).
# @stdout: prints the IPs, one per line, in addressN order.
# @warning: The .nmconnection file is root-owned 0600, so this needs root/sudo.
nw-config-ips() {
    local conf_file
    conf_file="/etc/NetworkManager/system-connections/${1}.nmconnection"
    [[ -f "${conf_file}" ]] || return 0
    awk '/^\[ipv4\]$/{flag=1;next}/^\[/{flag=0}flag&&/^address[0-9]+=/' "${conf_file}" \
        | sort -V \
        | cut -d'=' -f2 | cut -d',' -f1 | cut -d'/' -f1 \
        | grep -v '^$'
}
