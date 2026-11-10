#!/usr/bin/env bash
# @file: 130-create-builder-container.sh
# @source-dir: src/test/cli/tests/build-container-start/steps
# @group: test
# @category: step
# @description: Create RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Creates the RPM builder container from the builder image, with the RPM share folder mounted at /share.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if created, 1 otherwise.
create-builder-container() {
    local run_dir img share_dir
    run_dir="${1}"
    img="${TST_RPM_BUILDER_IMG}:${TST_FEDORA_VERSION}"
    mkdir -p "${TST_RPM_SHARE_DIR}" || { echo "The folder ${TST_RPM_SHARE_DIR} could not be created"; return 1; }
    share_dir="$(CDPATH='' cd -P -- "${TST_RPM_SHARE_DIR}" && pwd -P)"
    container-create "${TST_RPM_BUILDER_CNT}" "${share_dir}" "${img}" || { echo "The container ${TST_RPM_BUILDER_CNT} could not be created"; return 1; }
    write-log "${run_dir}" build-container-start "Container ${TST_RPM_BUILDER_CNT}: created from ${img}, /share is ${share_dir}"
}
