#!/usr/bin/env bash
# @file: 590-remove-precheck-from-vm.sh
# @source-dir: src/test/cli/tests/precheck-vm-clean/steps
# @group: test
# @category: step
# @description: Remove precheck from VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the copied precheck folder, TST_PRECHECK_VM_DIR, from the VM.
# @details:
#   The VM is otherwise left as it was, so later tests in the same run see a clean system.
# @arg: $1 - the run folder.
# @stdout: NOTE with the removed folder, or the problem.
# @exitcode: 0 if removed or the VM is not running, 1 if the removal failed.
remove-precheck-from-vm() {
    local run_dir vm dir
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_PRECHECK_VM_DIR}"
    if ! vm-running "${vm}"; then
        echo "NOTE: skipped, the VM is not running"
        return 0
    fi
    if ! vm-run "${vm}" rm -rf "${dir}"; then
        write-log "${run_dir}" precheck-vm-clean "Remove ${vm}:${dir}: failed"
        echo "${vm}:${dir} could not be removed"
        return 1
    fi
    write-log "${run_dir}" precheck-vm-clean "Remove ${vm}:${dir}: ok"
    echo "NOTE: removed ${dir}"
}
