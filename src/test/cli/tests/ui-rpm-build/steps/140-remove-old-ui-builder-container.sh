#!/usr/bin/env bash
# @file: 140-remove-old-ui-builder-container.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Remove old cockpit-podshift RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the cockpit-podshift RPM builder container if it exists.
# @arg: $1 - the run folder.
# @stdout: NOTE removed, none found or skipped.
# @exitcode: 0 if it does not exist anymore or skipped, 1 otherwise.
remove-old-ui-builder-container() {
    local run_dir
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    if ! container-cli inspect "${TST_UI_RPM_BUILDER_CNT}" >/dev/null 2>&1; then
        echo "NOTE: none found"
        return 0
    fi
    container-cli rm "${TST_UI_RPM_BUILDER_CNT}" || { echo "The container ${TST_UI_RPM_BUILDER_CNT} could not be removed"; return 1; }
    write-log "${run_dir}" ui-rpm-build "Container ${TST_UI_RPM_BUILDER_CNT}: removed"
    echo "NOTE: removed"
}
