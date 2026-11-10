#!/usr/bin/env bash
# @file: 120-copy-data-into-builder.sh
# @source-dir: src/test/cli/tests/build-data-copy/steps
# @group: test
# @category: step
# @description: Copy build data into RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies podshift.spec and the source tree into the builder, then removes files that do not belong in the package.
# @details:
#   podshift.spec goes to /builder/output/SOURCES and the source tree to
#   /builder/input/podshift-<branch>.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if copied, 1 otherwise.
copy-data-into-builder() {
    local run_dir repo_root raw_input junk
    run_dir="${1}"
    repo_root="$(pwd -P)"
    raw_input="/builder/input/podshift-${TST_SOURCE_BRANCH}"
    container-copy "${repo_root}/podshift.spec" "${TST_RPM_BUILDER_CNT}:/builder/output/SOURCES/" || { echo "podshift.spec could not be copied"; return 1; }
    container-copy "${repo_root}" "${TST_RPM_BUILDER_CNT}:/builder/input/" || { echo "The source tree could not be copied"; return 1; }
    container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" mv "/builder/input/$(basename "${repo_root}")" "${raw_input}" || { echo "The source tree could not be moved to ${raw_input}"; return 1; }
    for junk in .DS_Store .gitattributes .gitignore .idea .git .run; do
        container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" find "${raw_input}" -name "${junk}" -prune -exec rm -rf {} + || { echo "${junk} could not be removed"; return 1; }
    done
    write-log "${run_dir}" build-data-copy "Build data: copied from ${repo_root}"
}
