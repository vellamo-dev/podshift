#!/usr/bin/env bash
# @file: 110-check-bats-for-quadlet-lifecycle.sh
# @source-dir: src/test/cli/tests/unit-quadlet-lifecycle/steps
# @group: test
# @category: step
# @description: bats and jq installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that bats and jq are installed and that the remove helper is there.
# @arg: $1 - the run folder.
# @stdout: NOTE with the bats path and version, or the problem and a Fix line.
# @exitcode: 0 if all are there, 1 if the helper is missing, 3 if bats or jq is missing (cannot run here).
check-bats-for-quadlet-lifecycle() {
    local run_dir script tool
    run_dir="${1}"
    script="src/server/opt/podshift/fn/quadlet/remove-item.sh"
    for tool in bats jq; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            echo "${tool} not found. The quadlet lifecycle tests run with it."
            if [[ "${tool}" == "bats" ]]; then
                echo "Fix: ${TST_INSTALL_CMD} ${TST_BATS_PKG}"
            else
                echo "Fix: ${TST_INSTALL_CMD} jq"
            fi
            return 3
        fi
    done
    if [[ ! -f "${script}" ]]; then
        echo "${script} was not found"
        return 1
    fi
    write-log "${run_dir}" unit-quadlet-lifecycle "bats: $(command -v bats), $(bats --version)"
    echo "NOTE: $(command -v bats), $(bats --version)"
}
