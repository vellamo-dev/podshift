#!/usr/bin/env bash
# @file: 510-remove-libvirt-installer-vm.sh
# @source-dir: src/test/cli/tests/clean-containers/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Remove RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops and removes the RPM installer VM and its disk in the libvirt pool, if they exist.
# @arg: $1 - the run folder.
# @stdout: NOTE with the VM name and what was removed, or none found.
# @exitcode: 0 if neither exists anymore, 1 otherwise.
remove-libvirt-installer-vm() {
    local run_dir vol removed
    run_dir="${1}"
    vol="${TST_RPM_INSTALLER_VM}.qcow2"
    removed=()
    if vm-exists "${TST_RPM_INSTALLER_VM}"; then
        if vm-running "${TST_RPM_INSTALLER_VM}"; then
            vm-virsh destroy "${TST_RPM_INSTALLER_VM}" >/dev/null 2>&1 || { echo "The VM ${TST_RPM_INSTALLER_VM} could not be stopped"; return 1; }
        fi
        vm-virsh undefine "${TST_RPM_INSTALLER_VM}" >/dev/null 2>&1 || { echo "The VM ${TST_RPM_INSTALLER_VM} could not be removed"; return 1; }
        removed+=(VM)
    fi
    if vm-virsh vol-info --pool "${TST_VM_POOL}" "${vol}" >/dev/null 2>&1; then
        vm-virsh vol-delete --pool "${TST_VM_POOL}" "${vol}" >/dev/null 2>&1 \
            || { echo "The disk ${vol} in the libvirt pool ${TST_VM_POOL} could not be removed"; return 1; }
        removed+=(disk)
    fi
    if (( ${#removed[@]} == 0 )); then
        echo "NOTE: ${TST_RPM_INSTALLER_VM} none found"
        return 0
    fi
    write-log "${run_dir}" clean-containers "VM ${TST_RPM_INSTALLER_VM}: removed ${removed[*]}"
    echo "NOTE: ${TST_RPM_INSTALLER_VM} removed ${removed[*]}"
}
