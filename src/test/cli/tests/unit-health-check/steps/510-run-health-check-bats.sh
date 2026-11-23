#!/usr/bin/env bash
# @file: 510-run-health-check-bats.sh
# @source-dir: src/test/cli/tests/unit-health-check/steps
# @group: test
# @category: step
# @description: Run health-check tests.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the stubbed health-check bats tests and prints each result as DETAIL.
# @details:
#   The tests stub the config loaders, so no VM, network or root is needed. bats runs with a
#   clean environment, and its output is saved to unit-health-check.log.
# @arg: $1 - the run folder.
# @stdout: NOTE with the counts, and one DETAIL line per test, failed ones first.
# @exitcode: 0 if all passed, 2 otherwise (PodShift problem).
run-health-check-bats() {
    local run_dir log bats_dir podshift_dir rc passed failed
    run_dir="${1}"
    log="${run_dir}/unit-health-check.log"
    bats_dir="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/../scripts" && pwd -P)"
    podshift_dir="$(CDPATH='' cd -P -- "${TST_PODSHIFT_DIR}" && pwd -P)" || return 2
    # A clean environment, so no variable from this shell changes the result.
    env -i PATH="${PATH}" HOME="${HOME}" TST_PODSHIFT_DIR="${podshift_dir}" \
        bats --tap "${bats_dir}" >"${log}" 2>&1
    rc=$?
    passed="$(grep -c '^ok ' "${log}")"
    failed="$(grep -c '^not ok ' "${log}")"
    write-log "${run_dir}" unit-health-check "Health-check tests: ${passed} passed, ${failed} failed, bats exit ${rc}"
    echo "NOTE: ${passed} passed, ${failed} failed, saved in unit-health-check.log"
    # Failed tests first, so the summary names the first failure.
    grep -E '^not ok |^# ' "${log}" | sed 's/^/DETAIL: /'
    grep -E '^ok ' "${log}" | sed 's/^/DETAIL: /'
    [[ "${rc}" -eq 0 && "${passed}" -gt 0 ]] || return 2
}
