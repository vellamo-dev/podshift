#!/usr/bin/env bash
# @file: 110-check-bats-installed.sh
# @source-dir: src/test/cli/tests/unit-pure-functions/steps
# @group: test
# @category: step
# @description: bats installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that bats is installed.
# @details:
#   The unit tests run with it.
# @arg: $1 - the run folder.
# @stdout: NOTE with the path and version, or the problem and a Fix line.
# @exitcode: 0 if installed, 3 otherwise (cannot run here).
check-bats-installed() {
    if ! command -v bats >/dev/null 2>&1; then
        echo "bats not found. The unit tests run with it."
        echo "Fix: ${TST_INSTALL_CMD} ${TST_BATS_PKG}"
        return 3
    fi
    echo "NOTE: $(command -v bats), $(bats --version)"
}
