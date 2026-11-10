#!/usr/bin/env bash
# @file: 510-verify-no-vm.sh
# @source-dir: src/test/cli/tests/clean-all/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Verify no RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM, its disk in the libvirt pool and the built disk in TST_VM_IMAGE_DIR are gone.
# @arg: $1 - the run folder (not used, clean-all keeps no log).
# @stdout: a DETAIL line for each thing still left.
# @exitcode: 0 if all are gone, 1 otherwise.
verify-no-vm() {
    local left disk
    left=0
    disk="${TST_VM_IMAGE_DIR}/${TST_RPM_INSTALLER_IMG}-${TST_FEDORA_VERSION}.qcow2"
    if vm-exists "${TST_RPM_INSTALLER_VM}"; then
        echo "DETAIL: VM ${TST_RPM_INSTALLER_VM}"
        left=$((left + 1))
    fi
    if vm-virsh vol-info --pool "${TST_VM_POOL}" "${TST_RPM_INSTALLER_VM}.qcow2" >/dev/null 2>&1; then
        echo "DETAIL: disk ${TST_RPM_INSTALLER_VM}.qcow2 in the libvirt pool ${TST_VM_POOL}"
        left=$((left + 1))
    fi
    if [[ -e "${disk}" ]]; then
        echo "DETAIL: disk ${disk}"
        left=$((left + 1))
    fi
    (( left == 0 )) && return 0
    echo "NOTE: ${left} left"
    return 1
}
