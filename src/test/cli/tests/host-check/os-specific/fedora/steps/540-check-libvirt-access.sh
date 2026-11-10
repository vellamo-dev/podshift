#!/usr/bin/env bash
# @file: 540-check-libvirt-access.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/fedora/steps
# @group: test
# @category: step
# @description: libvirt access.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that libvirt is running and usable without a password, with its default network and pool active.
# @details:
#   The storage pool is TST_VM_POOL.
# @arg: $1 - the run folder.
# @stdout: each problem and how to fix it.
# @exitcode: 0 if libvirt is usable, 3 otherwise (cannot run here).
check-libvirt-access() {
    local run_dir user state
    run_dir="${1}"
    user="$(id -un)"
    if ! systemctl is-active --quiet virtqemud.socket && ! systemctl is-active --quiet libvirtd; then
        write-log "${run_dir}" host-check "libvirt: daemon not running"
        echo "libvirt is not running"
        echo "Fix: sudo systemctl enable --now virtqemud.socket"
        return 3
    fi
    # Without the group, virsh asks for a password, so stop before calling it.
    if ! id -nG | grep -qw libvirt; then
        write-log "${run_dir}" host-check "libvirt: ${user} not in the libvirt group"
        echo "${user} is not in the libvirt group"
        echo "Fix: sudo usermod -aG libvirt ${user}, then log out and in again"
        return 3
    fi
    state="$(timeout 10 virsh -c qemu:///system net-info default </dev/null 2>/dev/null | awk '/^Active:/ { print $2 }')"
    write-log "${run_dir}" host-check "libvirt: running, ${user} in group, default network active: ${state:-unknown}"
    if [[ "${state}" != "yes" ]]; then
        echo "The libvirt default network is not active"
        echo "Fix: sudo virsh net-start default && sudo virsh net-autostart default"
        return 3
    fi
    state="$(timeout 10 virsh -c qemu:///system pool-info "${TST_VM_POOL}" </dev/null 2>/dev/null | awk '/^State:/ { print $2 }')"
    write-log "${run_dir}" host-check "libvirt: storage pool ${TST_VM_POOL} state: ${state:-missing}"
    if [[ -z "${state}" ]]; then
        echo "The libvirt storage pool ${TST_VM_POOL} does not exist"
        echo "Fix: virsh -c qemu:///system pool-define-as ${TST_VM_POOL} dir --target /var/lib/libvirt/images && virsh -c qemu:///system pool-start ${TST_VM_POOL} && virsh -c qemu:///system pool-autostart ${TST_VM_POOL}"
        return 3
    fi
    if [[ "${state}" != "running" ]]; then
        echo "The libvirt storage pool ${TST_VM_POOL} is not active"
        echo "Fix: virsh -c qemu:///system pool-start ${TST_VM_POOL} && virsh -c qemu:///system pool-autostart ${TST_VM_POOL}"
        return 3
    fi
}
