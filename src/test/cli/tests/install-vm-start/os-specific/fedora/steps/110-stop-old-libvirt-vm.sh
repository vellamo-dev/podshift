#!/usr/bin/env bash
# @file: 110-stop-old-libvirt-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Stop old RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the RPM installer VM if it is running.
# @details:
#   It is powered off at once, since it is removed next anyway.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped or not running.
# @exitcode: 0 if it is not running anymore, 1 otherwise.
stop-old-libvirt-vm() {
    local run_dir
    run_dir="${1}"
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "NOTE: not running"
        return 0
    fi
    if ! vm-virsh destroy "${TST_RPM_INSTALLER_VM}" >/dev/null 2>&1; then
        write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: stop failed"
        echo "The VM ${TST_RPM_INSTALLER_VM} could not be stopped"
        return 1
    fi
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: stopped"
    echo "NOTE: stopped"
}
