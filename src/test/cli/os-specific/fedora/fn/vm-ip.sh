#!/usr/bin/env bash
# @file: vm-ip.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Prints the IP address of a VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the IPv4 address that libvirt's DHCP gave the VM, or nothing if it has none yet.
# @arg: $1 - the VM name.
# @stdout: the IP address.
vm-ip() {
    vm-virsh domifaddr "${1}" 2>/dev/null | awk '$3 == "ipv4" { split($4, a, "/"); print a[1]; exit }'
}
