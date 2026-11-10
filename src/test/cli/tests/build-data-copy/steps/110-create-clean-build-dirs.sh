#!/usr/bin/env bash
# @file: 110-create-clean-build-dirs.sh
# @source-dir: src/test/cli/tests/build-data-copy/steps
# @group: test
# @category: step
# @description: Create clean build folders.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Recreates /builder/input and /builder/output with its rpmbuild folders inside the RPM builder container.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if the folders are ready, 1 otherwise.
create-clean-build-dirs() {
    local run_dir
    run_dir="${1}"
    container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" rm -rf /builder/input /builder/output || { echo "The old build folders could not be removed"; return 1; }
    container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" mkdir -p /builder/input /builder/output/BUILD /builder/output/SOURCES /builder/output/RPMS /builder/output/SRPMS || { echo "The build folders could not be created"; return 1; }
    write-log "${run_dir}" build-data-copy "Build folders: /builder/input and /builder/output created"
}
