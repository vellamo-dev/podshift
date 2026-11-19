#!/usr/bin/env bash
# @file: 110-check-bats-for-precheck.sh
# @source-dir: src/test/cli/tests/precheck-unit/steps
# @group: test
# @category: step
# @description: bats installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that bats is installed and that the precheck script is there.
# @arg: $1 - the run folder.
# @stdout: NOTE with the bats path and version, or the problem and a Fix line.
# @exitcode: 0 if both are there, 1 if the precheck script is missing, 3 if bats is missing (cannot run here).
check-bats-for-precheck() {
    local run_dir script
    run_dir="${1}"
    script="utils/portable/precheck.sh"
    if ! command -v bats >/dev/null 2>&1; then
        echo "bats not found. The precheck tests run with it."
        echo "Fix: ${TST_INSTALL_CMD} ${TST_BATS_PKG}"
        return 3
    fi
    if [[ ! -f "${script}" ]]; then
        echo "${script} was not found"
        return 1
    fi
    write-log "${run_dir}" precheck-unit "bats: $(command -v bats), $(bats --version)"
    echo "NOTE: $(command -v bats), $(bats --version)"
}
