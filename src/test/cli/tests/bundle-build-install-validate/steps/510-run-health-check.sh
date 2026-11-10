#!/usr/bin/env bash
# @file: 510-run-health-check.sh
# @source-dir: src/test/cli/tests/bundle-build-install-validate/steps
# @group: test
# @category: step
# @description: Run PodShift health check.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift health-check as root in the installer VM with --plain and saves the report to health-check.log.
# @details:
#   Only checks that the command works; the health result itself does not fail the step.
# @arg: $1 - the run folder.
# @stdout: NOTE with the health result.
# @exitcode: 0 if the health check ran, 2 if it did not (PodShift problem).
run-health-check() {
    local run_dir rc result
    run_dir="${1}"
    vm-run "${TST_RPM_INSTALLER_VM}" podshift --plain health-check >"${run_dir}/health-check.log" 2>&1
    rc=$?
    # The line under "Result:", without its indent and icon.
    result="$(awk '/^ *Result:$/ { getline; sub(/^ *[^ ]+ /, ""); print }' "${run_dir}/health-check.log" | tail -n 1)"
    write-log "${run_dir}" bundle-build-install-validate "Health check: exit ${rc}, ${result:-no result}"
    if [[ "${rc}" -ne 0 || -z "${result}" ]]; then
        echo "podshift health-check did not finish (exit ${rc}), see health-check.log"
        tail -n 5 "${run_dir}/health-check.log" | sed 's/^/DETAIL: /'
        return 2
    fi
    echo "NOTE: ${result}, see health-check.log"
}
