#!/usr/bin/env bash
# @file: 520-run-precheck-json.sh
# @source-dir: src/test/cli/tests/precheck-vm-clean/steps
# @group: test
# @category: step
# @description: Precheck JSON output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the precheck with --json in the VM and checks its result, exit_code and the plain run's exit code.
# @details:
#   It runs as the same user as the plain step. The JSON goes to precheck.json and stderr to
#   precheck-json.err. The fields are read with sed, so jq is not needed. exit_code must match the
#   real exit code, result must be its name, and both must be Ready or Ready with warnings. When
#   precheck-plain.log is in the run folder, its exit code must be the same. It skips when
#   TST_PRECHECK_MODE is plain.
# @arg: $1 - the run folder.
# @stdout: NOTE with the result and exit code, or the problems as DETAIL lines.
# @exitcode: 0 if all match, 1 if SSH failed, 2 otherwise (PodShift problem), 3 if the VM is not running.
run-precheck-json() {
    local run_dir vm file json err rc result code expected plain_code user who bad
    local -a runner
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    file="${TST_PRECHECK_VM_DIR}/precheck.sh"
    json="${run_dir}/precheck.json"
    err="${run_dir}/precheck-json.err"
    runner=()
    who="root"
    bad=0
    if [[ "${TST_PRECHECK_MODE}" == "plain" ]]; then
        echo "NOTE: skipped, TST_PRECHECK_MODE is plain"
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
    vm-run "${vm}" "${runner[@]}" bash "${file}" --json >"${json}" 2>"${err}"
    rc=$?
    if [[ "${rc}" -eq 255 ]]; then
        write-log "${run_dir}" precheck-vm-clean "Precheck JSON as ${who}: SSH failed"
        echo "SSH to ${vm} failed, see precheck-json.err"
        tail -n 5 "${err}" | sed 's/^/DETAIL: /'
        return 1
    fi
    result="$(sed -n 's/^  "result": "\(.*\)",$/\1/p' "${json}" | head -n 1)"
    code="$(sed -n 's/^  "exit_code": \([0-9][0-9]*\),$/\1/p' "${json}" | head -n 1)"
    write-log "${run_dir}" precheck-vm-clean "Precheck JSON as ${who}: exit ${rc}, result ${result:-none}, exit_code ${code:-none}"
    case "${rc}" in
        0) expected="Ready" ;;
        1) expected="Ready with warnings" ;;
        2) expected="Not possible" ;;
        3) expected="Installed" ;;
        *) expected="" ;;
    esac
    if [[ "$(head -c 1 "${json}")" != "{" || "$(tail -n 1 "${json}")" != "}" ]]; then
        echo "DETAIL: precheck.json does not start with { and end with }"
        bad=$((bad + 1))
    fi
    if [[ "${code}" != "${rc}" ]]; then
        echo "DETAIL: exit_code is '${code:-missing}', the script exited ${rc}"
        bad=$((bad + 1))
    fi
    if [[ -z "${expected}" || "${result}" != "${expected}" ]]; then
        echo "DETAIL: result is '${result:-missing}', expected '${expected:-a known result}' for exit ${rc}"
        bad=$((bad + 1))
    fi
    if [[ "${rc}" -ne 0 && "${rc}" -ne 1 ]]; then
        echo "DETAIL: expected Ready or Ready with warnings (exit 0 or 1), got exit ${rc}"
        bad=$((bad + 1))
    fi
    if [[ -f "${run_dir}/precheck-plain.log" ]]; then
        plain_code="$(sed -n 's/^ *Result: .* (exit \([0-9]*\))$/\1/p' "${run_dir}/precheck-plain.log" | tail -n 1)"
        if [[ "${plain_code}" != "${rc}" ]]; then
            echo "DETAIL: the plain run exited ${plain_code:-unknown}, the JSON run ${rc}"
            bad=$((bad + 1))
        fi
    fi
    if (( bad > 0 )); then
        echo "NOTE: ${result:-no result} (exit ${rc}), ${bad} problems"
        echo "The JSON output is not as expected, see precheck.json"
        tail -n 5 "${err}" | sed 's/^/DETAIL: /'
        return 2
    fi
    echo "NOTE: ${result} (exit ${rc}), as ${who}, saved in precheck.json"
}
