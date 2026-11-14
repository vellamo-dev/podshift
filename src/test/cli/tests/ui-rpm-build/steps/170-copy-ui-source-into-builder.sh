#!/usr/bin/env bash
# @file: 170-copy-ui-source-into-builder.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Copy cockpit-podshift source into builder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies the cockpit-podshift project, without local junk, into clean build folders in the builder.
# @details:
#   The project is packed on the host into artifacts/tmp/ui-rpm-build/source.tar, without
#   node_modules, artifacts, .git, .idea, .run, .env and .DS_Store. It is unpacked to
#   /builder/input/cockpit-podshift-<branch>, and the spec is copied to /builder/output/SOURCES.
# @arg: $1 - the run folder.
# @stdout: the problem, if any, or NOTE skipped.
# @exitcode: 0 if copied or skipped, 1 otherwise.
copy-ui-source-into-builder() {
    local run_dir tmp_dir src_tar raw_input
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    tmp_dir="artifacts/tmp/ui-rpm-build"
    src_tar="${tmp_dir}/source.tar"
    raw_input="/builder/input/cockpit-podshift-${TST_UI_SOURCE_BRANCH}"
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" rm -rf /builder/input /builder/output || { echo "The old build folders could not be removed"; return 1; }
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" mkdir -p "${raw_input}" /builder/output/BUILD /builder/output/SOURCES /builder/output/RPMS /builder/output/SRPMS || { echo "The build folders could not be created"; return 1; }
    mkdir -p "${tmp_dir}" || { echo "The folder ${tmp_dir} could not be created"; return 1; }
    rm -f "${src_tar}"
    # COPYFILE_DISABLE keeps macOS ._ files out of the tar.
    COPYFILE_DISABLE=1 tar --no-xattrs -C "${TST_UI_SOURCE}" \
        --exclude=node_modules --exclude=artifacts --exclude=.git --exclude=.gitignore --exclude=.gitattributes \
        --exclude=.idea --exclude=.run --exclude=.env --exclude='.env.*' --exclude=.DS_Store --exclude='._*' \
        -cf "${src_tar}" . || { echo "The cockpit-podshift source could not be packed"; return 1; }
    container-copy "${src_tar}" "${TST_UI_RPM_BUILDER_CNT}:/builder/input/" || { echo "The source could not be copied into ${TST_UI_RPM_BUILDER_CNT}"; return 1; }
    rm -f "${src_tar}"
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" tar --no-same-owner -C "${raw_input}" -xf /builder/input/source.tar || { echo "The source could not be unpacked to ${raw_input}"; return 1; }
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" rm -f /builder/input/source.tar || { echo "source.tar could not be removed"; return 1; }
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" cp "${raw_input}/cockpit-podshift.spec" /builder/output/SOURCES/ || { echo "cockpit-podshift.spec could not be copied to SOURCES"; return 1; }
    write-log "${run_dir}" ui-rpm-build "Build data: copied from ${TST_UI_SOURCE} to ${raw_input}"
}
