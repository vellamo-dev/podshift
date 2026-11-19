#!/usr/bin/env bash
# @file: 110-stop-builder-container.sh
# @source-dir: src/test/cli/tests/build-container-start/steps
# @group: test
# @category: step
# @description: Stop old RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the RPM builder container if it is running.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped or not running.
# @exitcode: 0 if it is not running anymore, 1 otherwise.
stop-builder-container() {
    local run_dir
    run_dir="${1}"
    container-stop-if-running "${run_dir}" build-container-start "${TST_RPM_BUILDER_CNT}"
}
