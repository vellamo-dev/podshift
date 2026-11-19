#!/usr/bin/env bash
# @file: 510-run-precheck-plain.sh
# @source-dir: src/test/cli/tests/precheck-vm-clean/steps
# @group: test
# @category: step
# @description: Precheck plain output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the precheck with --plain in the VM and passes when it says Ready or Ready with warnings.
# @details:
#   It runs as root when TST_PRECHECK_AS_ROOT is true (vm-run logs in as root, so the dnf dry run is
#   included), otherwise as this computer's user in the VM, or nobody when that user is not there.
#   The output is saved to precheck-plain.log. It skips when TST_PRECHECK_MODE is json.
# @arg: $1 - the run folder.
# @stdout: NOTE with the result and exit code, DETAIL lines for warnings and blockers, or the end of the output.
# @exitcode: 0 if exit 0 or 1, 1 if SSH failed, 2 for any other result (PodShift problem), 3 if the VM is not running.
run-precheck-plain() {
    local run_dir vm file log rc result user who
    local -a runner
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    file="${TST_PRECHECK_VM_DIR}/precheck.sh"
    log="${run_dir}/precheck-plain.log"
    runner=()
    who="root"
    if [[ "${TST_PRECHECK_MODE}" == "json" ]]; then
        echo "NOTE: skipped, TST_PRECHECK_MODE is json"
        return 0
    fi
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test precheck-vm-clean"
        return 3
    fi
    if [[ "${TST_PRECHECK_AS_ROOT}" != "true" ]]; then
        user="$(id -un)"
        vm-run "${vm}" getent passwd "${user}" >/dev/null 2>&1 || user="nobody"
        runner=(runuser -u "${user}" --)
        who="${user}"
    fi
    vm-run "${vm}" "${runner[@]}" bash "${file}" --plain >"${log}" 2>&1
    rc=$?
    result="$(sed -n 's/^ *Result: \(.*\) (exit [0-9]*)$/\1/p' "${log}" | tail -n 1)"
    write-log "${run_dir}" precheck-vm-clean "Precheck plain as ${who}: exit ${rc}, ${result:-no result}"
    if [[ "${rc}" -eq 255 ]]; then
        echo "SSH to ${vm} failed, see precheck-plain.log"
        tail -n 5 "${log}" | sed 's/^/DETAIL: /'
        return 1
    fi
    if [[ -z "${result}" ]]; then
        echo "The precheck did not finish (exit ${rc}), see precheck-plain.log"
        tail -n 15 "${log}" | sed 's/^/DETAIL: /'
        return 2
    fi
    echo "NOTE: ${result} (exit ${rc}), as ${who}"
    if [[ "${rc}" -ne 0 && "${rc}" -ne 1 ]]; then
        echo "Expected Ready or Ready with warnings (exit 0 or 1), got ${result} (exit ${rc})"
        tail -n 15 "${log}" | sed 's/^/DETAIL: /'
        return 2
    fi
    # Warnings and blockers from the Progress lists, not the verdicts, without the report indent.
    awk '/^    Progress:$/ { p = 1; next } /^    Verdict:$/ { p = 0; next } p && /^        (⚠|✘) / { sub(/^        /, ""); print "DETAIL: " $0 }' "${log}"
    echo "DETAIL: Full output: precheck-plain.log"
}
