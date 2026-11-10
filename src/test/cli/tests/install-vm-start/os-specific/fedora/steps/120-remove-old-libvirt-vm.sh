#!/usr/bin/env bash
# @file: 120-remove-old-libvirt-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Remove old RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the RPM installer VM and its disk in the libvirt pool, if they exist.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or none found.
# @exitcode: 0 if neither exists anymore, 1 otherwise.
remove-old-libvirt-vm() {
    local run_dir vol removed
    run_dir="${1}"
    vol="${TST_RPM_INSTALLER_VM}.qcow2"
    removed=()
    if vm-exists "${TST_RPM_INSTALLER_VM}"; then
        if ! vm-virsh undefine "${TST_RPM_INSTALLER_VM}" >/dev/null 2>&1; then
            write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: remove failed"
            echo "The VM ${TST_RPM_INSTALLER_VM} could not be removed"
            return 1
        fi
        removed+=(VM)
    fi
    if vm-virsh vol-info --pool "${TST_VM_POOL}" "${vol}" >/dev/null 2>&1; then
        if ! vm-virsh vol-delete --pool "${TST_VM_POOL}" "${vol}" >/dev/null 2>&1; then
            write-log "${run_dir}" install-vm-start "Disk ${TST_VM_POOL}/${vol}: remove failed"
            echo "The disk ${vol} in the libvirt pool ${TST_VM_POOL} could not be removed"
            return 1
        fi
        removed+=(disk)
    fi
    if (( ${#removed[@]} == 0 )); then
        echo "NOTE: none found"
        return 0
    fi
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: removed ${removed[*]}"
    echo "NOTE: removed ${removed[*]}"
}
