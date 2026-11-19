#!/usr/bin/env bash
# @file: 110-start-installer-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/steps
# @group: test
# @category: step
# @description: Start RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Starts the existing RPM installer VM if it is stopped, without recreating it.
# @arg: $1 - the run folder.
# @stdout: NOTE started or already running, or the problem.
# @exitcode: 0 if it is running, 1 otherwise.
start-installer-vm() {
    local run_dir
    run_dir="${1}"
    vm-start-if-stopped "${run_dir}" install-vm-start "${TST_RPM_INSTALLER_VM}"
}
