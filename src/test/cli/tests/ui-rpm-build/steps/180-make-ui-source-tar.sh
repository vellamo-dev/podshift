#!/usr/bin/env bash
# @file: 180-make-ui-source-tar.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Create cockpit-podshift source tar package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Packs the source into SOURCES/<branch>.tar.gz like the GitHub archive, then checks it.
# @details:
#   The tar has the folder cockpit-podshift-<branch>, the same name COPR gets from GitHub. It must
#   have the spec and dist/manifest.json, and no node_modules, artifacts, .git, .idea, .run or .env.
# @arg: $1 - the run folder.
# @stdout: NOTE with the tar name, the problems, or NOTE skipped.
# @exitcode: 0 if made and checked or skipped, 1 otherwise.
make-ui-source-tar() {
    local run_dir branch tar_file rc
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    branch="${TST_UI_SOURCE_BRANCH}"
    tar_file="/builder/output/SOURCES/${branch}.tar.gz"
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c "cd /builder/input && tar --format=gnu --no-acls --no-xattrs --no-selinux --numeric-owner --owner=0 --group=0 -czf ${tar_file} cockpit-podshift-${branch}" || { echo "The source tar package could not be made"; return 1; }
    rc=0
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 1 "tar is valid" "tar -tzf ${tar_file}" || rc=1
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 1 "spec file in tar" "tar -tzf ${tar_file} | grep -qx cockpit-podshift-${branch}/cockpit-podshift.spec" || rc=1
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 1 "dist/manifest.json in tar" "tar -tzf ${tar_file} | grep -qx cockpit-podshift-${branch}/dist/manifest.json" || rc=1
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 1 "no junk in tar" "! tar -tzf ${tar_file} | grep -Eq '/(node_modules|artifacts|\.git|\.idea|\.run|\.env|\.DS_Store)(/|\$)'" || rc=1
    [[ "${rc}" -eq 0 ]] || return "${rc}"
    write-log "${run_dir}" ui-rpm-build "Source package: ${tar_file} made"
    echo "NOTE: ${branch}.tar.gz"
}
