#!/usr/bin/env bash
# @file: 110-check-ui-source.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Check cockpit-podshift project.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether the cockpit-podshift project is there, from TST_UI_PRESENT.
# @details:
#   When it is missing, this and every later step pass with a skipped note.
# @arg: $1 - the run folder.
# @stdout: NOTE with the project folder, or that it was skipped.
# @exitcode: always 0.
check-ui-source() {
    local run_dir
    run_dir="${1}"
    if [[ "${TST_UI_PRESENT}" != "true" ]]; then
        write-log "${run_dir}" ui-rpm-build "cockpit-podshift: not found at ${TST_UI_SOURCE}, skipped"
        echo "NOTE: cockpit-podshift not found, skipped"
        return 0
    fi
    write-log "${run_dir}" ui-rpm-build "cockpit-podshift: ${TST_UI_SOURCE}, branch ${TST_UI_SOURCE_BRANCH}"
    write-log "${run_dir}" ui-rpm-build "Share folder: ${TST_UI_RPM_SHARE_DIR}"
    echo "NOTE: ${TST_UI_SOURCE}"
}
