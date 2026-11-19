#!/usr/bin/env bash
# @file: 510-verify-vm-stopped.sh
# @source-dir: src/test/cli/tests/install-vm-stop/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM is stopped.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM is not running, and logs whether it still exists.
# @arg: $1 - the run folder.
# @stdout: NOTE no VM, or the problem if it still runs.
# @exitcode: 0 if it is not running, 1 otherwise.
verify-vm-stopped() {
    local run_dir
    run_dir="${1}"
    if vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "The VM ${TST_RPM_INSTALLER_VM} is still running"
        return 1
    fi
    if vm-exists "${TST_RPM_INSTALLER_VM}"; then
        write-log "${run_dir}" install-vm-stop "VM ${TST_RPM_INSTALLER_VM}: exists, not running"
        return 0
    fi
    write-log "${run_dir}" install-vm-stop "VM ${TST_RPM_INSTALLER_VM}: no VM"
    echo "NOTE: no VM"
}
