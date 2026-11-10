#!/usr/bin/env bash
# @file: 510-verify-vm-running.sh
# @source-dir: src/test/cli/tests/install-vm-start/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM running.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM is listed as running.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if running, 1 otherwise.
verify-vm-running() {
    local run_dir
    run_dir="${1}"
    if vm-running "${TST_RPM_INSTALLER_VM}"; then
        write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: running"
        return 0
    fi
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: not running"
    echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
    return 1
}
