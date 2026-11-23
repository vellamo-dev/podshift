#!/usr/bin/env bash
# @file: 510-run-cli-network-bats.sh
# @source-dir: src/test/cli/tests/unit-cli-network/steps
# @group: test
# @category: step
# @description: Run network tests.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the stubbed network bats tests and prints each result as DETAIL.
# @details:
#   The tests stub the network facts, curl and the config, so no VM, real
#   network or root is needed. bats runs with a clean environment, and its output is saved to
#   unit-cli-network.log.
# @arg: $1 - the run folder.
# @stdout: NOTE with the counts, and one DETAIL line per test, failed ones first.
# @exitcode: 0 if all passed, 2 otherwise (PodShift problem).
run-cli-network-bats() {
    local run_dir log bats_dir rc passed failed skipped
    run_dir="${1}"
    log="${run_dir}/unit-cli-network.log"
    bats_dir="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/../scripts" && pwd -P)"
    # A clean environment, so no variable from this shell changes the result.
    env -i PATH="${PATH}" HOME="${HOME}" bats --tap "${bats_dir}" >"${log}" 2>&1
    rc=$?
    passed="$(grep -c '^ok ' "${log}")"
    failed="$(grep -c '^not ok ' "${log}")"
    skipped="$(grep -c '^ok .* # skip' "${log}")"
    write-log "${run_dir}" unit-cli-network "Network tests: ${passed} passed (${skipped} skipped), ${failed} failed, bats exit ${rc}"
    echo "NOTE: ${passed} passed (${skipped} skipped), ${failed} failed, saved in unit-cli-network.log"
    # Failed tests first, so the summary names the first failure.
    grep -E '^not ok |^# ' "${log}" | sed 's/^/DETAIL: /'
    grep -E '^ok ' "${log}" | sed 's/^/DETAIL: /'
    [[ "${rc}" -eq 0 && "${passed}" -gt 0 ]] || return 2
}
