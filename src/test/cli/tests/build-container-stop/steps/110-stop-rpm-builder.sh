#!/usr/bin/env bash
# @file: 110-stop-rpm-builder.sh
# @source-dir: src/test/cli/tests/build-container-stop/steps
# @group: test
# @category: step
# @description: Stop RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the RPM builder container if it is running, unless TST_KEEP_BUILDERS is true.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped, not running or kept, or the problem.
# @exitcode: 0 if it is not running anymore or kept, 1 otherwise.
stop-rpm-builder() {
    local run_dir
    run_dir="${1}"
    [[ "${TST_KEEP_BUILDERS}" != "true" ]] || { echo "NOTE: kept"; return 0; }
    container-stop-if-running "${run_dir}" build-container-stop "${TST_RPM_BUILDER_CNT}"
}
