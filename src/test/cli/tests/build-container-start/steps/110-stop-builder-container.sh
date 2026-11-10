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
    if ! container-running "${TST_RPM_BUILDER_CNT}"; then
        echo "NOTE: not running"
        return 0
    fi
    container-cli stop "${TST_RPM_BUILDER_CNT}" || { echo "The container ${TST_RPM_BUILDER_CNT} could not be stopped"; return 1; }
    write-log "${run_dir}" build-container-start "Container ${TST_RPM_BUILDER_CNT}: stopped"
    echo "NOTE: stopped"
}
