#!/usr/bin/env bash
# @file: 510-report-installed-health.sh
# @source-dir: src/test/cli/tests/postinstall-health-check/steps
# @group: test
# @category: step
# @description: PodShift health check.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift health-check as root in the installer VM and passes only when the system is healthy.
# @details:
#   It runs with --plain and --fail-if-unhealthy, saves the output to health-check.log, and reports
#   the totals plus every check, with a fix under each note, warning and issue.
# @arg: $1 - the run folder.
# @stdout: NOTE with the totals, and DETAIL lines for every check.
# @exitcode: 0 if healthy, 2 if not healthy or the health check did not finish (PodShift problem), 3 if the VM is not running.
report-installed-health() {
    local run_dir log rc result
    run_dir="${1}"
    log="${run_dir}/health-check.log"
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    vm-run "${TST_RPM_INSTALLER_VM}" podshift --plain health-check --fail-if-unhealthy >"${log}" 2>&1
    rc=$?
    # The line under "Result:", without its indent and icon.
    result="$(awk '/^ *Result:$/ { getline; sub(/^ *[^ ]+ /, ""); print }' "${log}" | tail -n 1)"
    write-log "${run_dir}" postinstall-health-check "Health check: exit ${rc}, ${result:-no result}"
    if [[ -z "${result}" ]]; then
        echo "podshift health-check did not finish (exit ${rc}), see health-check.log"
        tail -n 5 "${log}" | sed 's/^/DETAIL: /'
        return 2
    fi
    echo "NOTE: ${result}"
    if [[ "${rc}" -ne 0 ]]; then
        echo "Not healthy: ${result%% (*}"
    fi
    # Every check with its group, and the Fix lines, between the head line and the Result line, without the report indent.
    awk '/^ *Result:$/ { exit } NR > 1 && NF { sub(/^    /, ""); print "DETAIL: " $0 }' "${log}"
    echo "DETAIL: Full report: health-check.log"
    [[ "${rc}" -eq 0 ]] || return 2
}
