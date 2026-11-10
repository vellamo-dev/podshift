#!/usr/bin/env bash
# @file: 110-stop-old-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/mac/steps
# @group: test
# @category: step
# @description: Stop old RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the RPM installer VM if it is running.
# @details:
#   It is powered off at once, since it is removed next anyway, and because Lima's normal stop
#   needs SSH on port 22, which PodShift closes.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped or not running.
# @exitcode: 0 if it is not running anymore, 1 otherwise.
stop-old-vm() {
    local run_dir
    run_dir="${1}"
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "NOTE: not running"
        return 0
    fi
    vm stop -f "${TST_RPM_INSTALLER_VM}" >/dev/null 2>&1 || { echo "The VM ${TST_RPM_INSTALLER_VM} could not be stopped"; return 1; }
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: stopped"
    echo "NOTE: stopped"
}
