#!/usr/bin/env bash
# @file: 150-create-ui-builder-container.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Create cockpit-podshift RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Creates the cockpit-podshift RPM builder container, with TST_UI_RPM_SHARE_DIR mounted at /share.
# @arg: $1 - the run folder.
# @stdout: the problem, if any, or NOTE skipped.
# @exitcode: 0 if created or skipped, 1 otherwise.
create-ui-builder-container() {
    local run_dir img share_dir
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    img="${TST_UI_RPM_BUILDER_IMG}:${TST_FEDORA_VERSION}"
    mkdir -p "${TST_UI_RPM_SHARE_DIR}" || { echo "The folder ${TST_UI_RPM_SHARE_DIR} could not be created"; return 1; }
    share_dir="$(CDPATH='' cd -P -- "${TST_UI_RPM_SHARE_DIR}" && pwd -P)"
    container-create "${TST_UI_RPM_BUILDER_CNT}" "${share_dir}" "${img}" || { echo "The container ${TST_UI_RPM_BUILDER_CNT} could not be created"; return 1; }
    write-log "${run_dir}" ui-rpm-build "Container ${TST_UI_RPM_BUILDER_CNT}: created from ${img}, /share is ${share_dir}"
}
