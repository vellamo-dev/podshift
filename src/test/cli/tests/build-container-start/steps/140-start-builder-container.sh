#!/usr/bin/env bash
# @file: 140-start-builder-container.sh
# @source-dir: src/test/cli/tests/build-container-start/steps
# @group: test
# @category: step
# @description: Start RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Starts the RPM builder container.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if started, 1 otherwise.
start-builder-container() {
    local run_dir
    run_dir="${1}"
    container-cli start "${TST_RPM_BUILDER_CNT}" || { echo "The container ${TST_RPM_BUILDER_CNT} could not be started"; return 1; }
    write-log "${run_dir}" build-container-start "Container ${TST_RPM_BUILDER_CNT}: started"
}
