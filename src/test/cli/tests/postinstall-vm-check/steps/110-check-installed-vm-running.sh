#!/usr/bin/env bash
# @file: 110-check-installed-vm-running.sh
# @source-dir: src/test/cli/tests/postinstall-vm-check/steps
# @group: test
# @category: step
# @description: Installer VM running.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the installer VM is running, without starting it.
# @arg: $1 - the run folder.
# @stdout: the problem and how to fix it, if any.
# @exitcode: 0 if running, 3 otherwise (cannot run here).
check-installed-vm-running() {
    local run_dir
    run_dir="${1}"
    if vm-running "${TST_RPM_INSTALLER_VM}"; then
        write-log "${run_dir}" postinstall-vm-check "VM ${TST_RPM_INSTALLER_VM}: running"
        return 0
    fi
    write-log "${run_dir}" postinstall-vm-check "VM ${TST_RPM_INSTALLER_VM}: not running"
    echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
    echo "Fix: ./test bundle-build-install-validate"
    return 3
}
