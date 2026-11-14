#!/usr/bin/env bash
# @file: 160-start-ui-builder-container.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Start cockpit-podshift RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Starts the cockpit-podshift RPM builder container and checks that it runs and has rpmbuild.
# @arg: $1 - the run folder.
# @stdout: the problem, if any, or NOTE skipped.
# @exitcode: 0 if started or skipped, 1 otherwise.
start-ui-builder-container() {
    local run_dir
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    container-cli start "${TST_UI_RPM_BUILDER_CNT}" || { echo "The container ${TST_UI_RPM_BUILDER_CNT} could not be started"; return 1; }
    container-running "${TST_UI_RPM_BUILDER_CNT}" || { echo "The container ${TST_UI_RPM_BUILDER_CNT} is not running"; return 1; }
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" rpmbuild --version >/dev/null 2>&1 || { echo "rpmbuild does not work in ${TST_UI_RPM_BUILDER_CNT}"; return 1; }
    write-log "${run_dir}" ui-rpm-build "Container ${TST_UI_RPM_BUILDER_CNT}: started"
}
