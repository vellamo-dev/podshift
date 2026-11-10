#!/usr/bin/env bash
# @file: 510-print-quick-limit.sh
# @source-dir: src/test/cli/tests/quick/steps
# @group: test
# @category: step
# @description: Print the limit.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints that the quick checks passed and that build, install and runtime were not tested.
# @arg: $1 - the run folder.
# @stdout: NOTE with the limit line.
# @exitcode: 0 always.
print-quick-limit() {
    local run_dir
    run_dir="${1}"
    write-log "${run_dir}" quick "Quick checks passed. Build, install and runtime not tested."
    echo "NOTE: Quick checks passed. Build, install and runtime not tested."
}
