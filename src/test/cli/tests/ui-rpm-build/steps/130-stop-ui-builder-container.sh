#!/usr/bin/env bash
# @file: 130-stop-ui-builder-container.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Stop old cockpit-podshift RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the cockpit-podshift RPM builder container if it is running.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped, not running or skipped.
# @exitcode: 0 if it is not running anymore or skipped, 1 otherwise.
stop-ui-builder-container() {
    local run_dir
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    container-stop-if-running "${run_dir}" ui-rpm-build "${TST_UI_RPM_BUILDER_CNT}"
}
