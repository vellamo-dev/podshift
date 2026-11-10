#!/usr/bin/env bash
# @file: 510-verify-tar-package.sh
# @source-dir: src/test/cli/tests/build-source-tar/steps
# @group: test
# @category: step
# @description: Verify source tar package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks one thing inside the RPM builder container and logs the result.
# @arg: $1 - the run folder.
# @arg: $2 - what is checked, for example tar is valid.
# @arg: $3 - the shell command to run inside the container.
# @stdout: the problem, if any.
# @exitcode: 0 if the check passed, 2 otherwise.
verify-tar-check() {
    local run_dir what
    run_dir="${1}"
    what="${2}"
    if container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash -c "${3}" >/dev/null 2>&1; then
        write-log "${run_dir}" build-source-tar "Check ${what}: ok"
        return 0
    fi
    write-log "${run_dir}" build-source-tar "Check ${what}: failed"
    echo "${what}: failed"
    return 2
}

# @description: Checks that <branch>.tar.gz is a valid archive with the spec file and src/, and that postun.sh is staged.
# @arg: $1 - the run folder.
# @stdout: the problems, if any.
# @exitcode: 0 if all checks passed, 2 otherwise.
verify-tar-package() {
    local run_dir tar_file rc
    run_dir="${1}"
    tar_file="/builder/output/SOURCES/${TST_SOURCE_BRANCH}.tar.gz"
    rc=0
    verify-tar-check "${run_dir}" "tar is valid" "tar -tzf ${tar_file}" || rc=2
    verify-tar-check "${run_dir}" "spec file in tar" "tar -tzf ${tar_file} | grep -qx podshift-${TST_SOURCE_BRANCH}/podshift.spec" || rc=2
    verify-tar-check "${run_dir}" "src/ in tar" "tar -tzf ${tar_file} | grep -q '^podshift-${TST_SOURCE_BRANCH}/src/'" || rc=2
    verify-tar-check "${run_dir}" "postun.sh staged" "test -f /builder/output/SOURCES/postun.sh" || rc=2
    return "${rc}"
}
