#!/usr/bin/env bash
# @file: nw-common.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Shared network detection functions for the network feature and the NW loader.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the active network backend.
# @stdout: NetworkManager, systemd-networkd, or none.
nw-backend() {
    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        echo "NetworkManager"
    elif systemctl is-active --quiet systemd-networkd 2>/dev/null; then
        echo "systemd-networkd"
    else
        echo "none"
    fi
}

# @description: Prints the default-route device.
# @stdout: the device name (e.g. enp0s1), empty when there is no default route.
nw-device() {
    ip route show default 2>/dev/null | awk 'NR==1{print $5}'
}

# @description: Prints the default-route gateway.
# @stdout: the gateway address, empty when there is no default route.
nw-gateway() {
    ip route show default 2>/dev/null | awk 'NR==1{print $3}'
}

# @description: Prints the active NetworkManager connection name.
# @stdout: the connection name (e.g. HappyMac5G), empty when none.
nw-connection() {
    nmcli -t -f NAME connection show --active 2>/dev/null | grep -v '^lo$' | head -n1
}

# @description: Prints the IPv4 method of the active connection.
# @stdout: manual, auto, or unknown.
nw-mode() {
    local conn method
    conn="$(nw-connection)"
    [[ -n "${conn}" ]] || { echo "unknown"; return; }
    method="$(nmcli -t -f ipv4.method connection show "${conn}" 2>/dev/null | cut -d: -f2-)"
    echo "${method:-unknown}"
}

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

# @description: Prints the external IPv4 addresses, one per line.
# @stdout: the IPs; config addresses when manual, the live system when auto.
nw-ips() {
    local dev mode conn
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
