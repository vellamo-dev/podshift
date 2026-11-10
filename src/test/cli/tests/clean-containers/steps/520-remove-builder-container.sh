#!/usr/bin/env bash
# @file: 520-remove-builder-container.sh
# @source-dir: src/test/cli/tests/clean-containers/steps
# @group: test
# @category: step
# @description: Remove RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the RPM builder container if it exists, also when it is running.
# @arg: $1 - the run folder.
# @stdout: NOTE with the container name and removed or none found.
# @exitcode: 0 if it does not exist anymore, 1 otherwise.
remove-builder-container() {
    local run_dir
    run_dir="${1}"
    if ! container-cli inspect "${TST_RPM_BUILDER_CNT}" >/dev/null 2>&1; then
        echo "NOTE: ${TST_RPM_BUILDER_CNT} none found"
        return 0
    fi
    container-cli rm -f "${TST_RPM_BUILDER_CNT}" >/dev/null 2>&1 || { echo "The container ${TST_RPM_BUILDER_CNT} could not be removed"; return 1; }
    write-log "${run_dir}" clean-containers "Container ${TST_RPM_BUILDER_CNT}: removed"
    echo "NOTE: ${TST_RPM_BUILDER_CNT} removed"
}
