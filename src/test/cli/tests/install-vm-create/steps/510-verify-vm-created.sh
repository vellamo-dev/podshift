#!/usr/bin/env bash
# @file: 510-verify-vm-created.sh
# @source-dir: src/test/cli/tests/install-vm-create/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM created.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM exists and is not running yet.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if it exists and is stopped, 1 otherwise.
verify-vm-created() {
    local run_dir
    run_dir="${1}"
    if ! vm-exists "${TST_RPM_INSTALLER_VM}"; then
        write-log "${run_dir}" install-vm-create "VM ${TST_RPM_INSTALLER_VM}: missing"
        echo "The VM ${TST_RPM_INSTALLER_VM} does not exist"
        return 1
    fi
    if vm-running "${TST_RPM_INSTALLER_VM}"; then
        write-log "${run_dir}" install-vm-create "VM ${TST_RPM_INSTALLER_VM}: running"
        echo "The VM ${TST_RPM_INSTALLER_VM} is already running"
        return 1
    fi
    write-log "${run_dir}" install-vm-create "VM ${TST_RPM_INSTALLER_VM}: created, not running"
}
