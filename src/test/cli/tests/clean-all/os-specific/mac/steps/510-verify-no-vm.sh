#!/usr/bin/env bash
# @file: 510-verify-no-vm.sh
# @source-dir: src/test/cli/tests/clean-all/os-specific/mac/steps
# @group: test
# @category: step
# @description: Verify no RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM and its Lima base VM are gone.
# @arg: $1 - the run folder (not used, clean-all keeps no log).
# @stdout: a DETAIL line for each thing still left.
# @exitcode: 0 if all are gone, 1 otherwise.
verify-no-vm() {
    local left name
    left=0
    for name in "${TST_RPM_INSTALLER_VM}" "${TST_RPM_INSTALLER_BASE}"; do
        if vm-exists "${name}"; then
            echo "DETAIL: VM ${name}"
            left=$((left + 1))
        fi
    done
    (( left == 0 )) && return 0
    echo "NOTE: ${left} left"
    return 1
}
