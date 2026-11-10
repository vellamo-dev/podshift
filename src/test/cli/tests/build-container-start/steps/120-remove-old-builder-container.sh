#!/usr/bin/env bash
# @file: 120-remove-old-builder-container.sh
# @source-dir: src/test/cli/tests/build-container-start/steps
# @group: test
# @category: step
# @description: Remove old RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the RPM builder container if it exists.
# @arg: $1 - the run folder.
# @stdout: NOTE removed or none found.
# @exitcode: 0 if it does not exist anymore, 1 otherwise.
remove-old-builder-container() {
    local run_dir
    run_dir="${1}"
    if ! container-cli inspect "${TST_RPM_BUILDER_CNT}" >/dev/null 2>&1; then
        echo "NOTE: none found"
        return 0
    fi
    container-cli rm "${TST_RPM_BUILDER_CNT}" || { echo "The container ${TST_RPM_BUILDER_CNT} could not be removed"; return 1; }
    write-log "${run_dir}" build-container-start "Container ${TST_RPM_BUILDER_CNT}: removed"
    echo "NOTE: removed"
}
