#!/usr/bin/env bash
# @file: vm-ip.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Prints the IP address of a VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the IPv4 address that macOS gave the VM on Lima's vzNAT network, from /var/db/dhcpd_leases.
# @details:
#   The lease is found by the VM's fixed MAC address TST_VM_MAC, since the lease often has no name.
#   macOS writes the MAC without leading zeros (01 as 1), so both sides are compared that way. It
#   needs no SSH, so it also works after PodShift moves SSH to 1022. Prints nothing if there is no
#   lease.
# @arg: $1 - the VM name (not used, the VM is found by TST_VM_MAC).
# @stdout: the IP address.
vm-ip() {
    awk -v mac="${TST_VM_MAC}" '
        function norm(m,    a, n, i, x, out) {
            n = split(tolower(m), a, ":")
            out = ""
            for (i = 1; i <= n; i++) {
                x = a[i]
                sub(/^0+/, "", x)
                if (x == "") x = "0"
                out = out (i > 1 ? ":" : "") x
            }
            return out
        }
        BEGIN { want = norm(mac) }
        { sub(/^[ \t]+/, "") }
        /^\{/ { ip = ""; hw = "" }
        /^ip_address=/ { ip = substr($0, 12) }
        /^hw_address=/ { hw = substr($0, 12); sub(/^[0-9]+,/, "", hw) }
        /^\}/ { if (ip != "" && norm(hw) == want) { print ip; exit } }
    ' /var/db/dhcpd_leases 2>/dev/null
}
