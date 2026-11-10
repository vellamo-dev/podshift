#!/usr/bin/env bash
# @file: 120-remove-old-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/mac/steps
# @group: test
# @category: step
# @description: Remove old RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the RPM installer VM if it exists.
# @arg: $1 - the run folder.
# @stdout: NOTE removed or none found.
# @exitcode: 0 if it does not exist anymore, 1 otherwise.
remove-old-vm() {
    local run_dir
    run_dir="${1}"
    if ! vm-exists "${TST_RPM_INSTALLER_VM}"; then
        echo "NOTE: none found"
        return 0
    fi
    vm delete -f "${TST_RPM_INSTALLER_VM}" >/dev/null 2>&1 || { echo "The VM ${TST_RPM_INSTALLER_VM} could not be removed"; return 1; }
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: removed"
    echo "NOTE: removed"
}
