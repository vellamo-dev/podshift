#!/usr/bin/env bash
# @file: 110-check-ui-dist.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files/steps
# @group: test
# @category: step
# @description: Check the UI dist folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether ../cockpit-podshift/dist is present, from TST_DEV_SHARE.
# @details:
#   When it is missing, this and every later step pass with a skipped note.
# @arg: $1 - the run folder.
# @stdout: NOTE with the dist folder, or that it was skipped.
# @exitcode: always 0.
check-ui-dist() {
    local run_dir
    run_dir="${1}"
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        write-log "${run_dir}" postinstall-ui-sync-files "UI dist: not found, skipped"
        echo "NOTE: cockpit-podshift dist/ not found, skipped"
        return 0
    fi
    write-log "${run_dir}" postinstall-ui-sync-files "UI dist: ${TST_DEV_SHARE}"
    echo "NOTE: ${TST_DEV_SHARE}"
}
