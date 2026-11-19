#!/usr/bin/env bash
# @file: 110-stop-installer-vm.sh
# @source-dir: src/test/cli/tests/install-vm-stop/steps
# @group: test
# @category: step
# @description: Stop RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the RPM installer VM if it is running, without removing it.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped, not running or forced, or the problem.
# @exitcode: 0 if it is not running anymore, 1 otherwise.
stop-installer-vm() {
    local run_dir
    run_dir="${1}"
    vm-stop-if-running "${run_dir}" install-vm-stop "${TST_RPM_INSTALLER_VM}"
}
