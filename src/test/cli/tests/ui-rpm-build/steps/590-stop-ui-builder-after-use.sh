#!/usr/bin/env bash
# @file: 590-stop-ui-builder-after-use.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Stop cockpit-podshift RPM builder container after use.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the cockpit-podshift RPM builder container at the end, unless TST_KEEP_BUILDERS is true.
# @details:
#   It is only stopped, not removed. The next run replaces it with a fresh container.
# @arg: $1 - the run folder.
# @stdout: NOTE stopped, not running, kept or skipped, or the problem.
# @exitcode: 0 if it is not running anymore, kept or skipped, 1 otherwise.
stop-ui-builder-after-use() {
    local run_dir
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    [[ "${TST_KEEP_BUILDERS}" != "true" ]] || { echo "NOTE: kept"; return 0; }
    container-stop-if-running "${run_dir}" ui-rpm-build "${TST_UI_RPM_BUILDER_CNT}"
}
