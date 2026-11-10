#!/usr/bin/env bash
# @file: 510-verify-data-in-builder.sh
# @source-dir: src/test/cli/tests/build-data-copy/steps
# @group: test
# @category: step
# @description: Verify build data in RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks one thing inside the RPM builder container and logs the result.
# @arg: $1 - the run folder.
# @arg: $2 - what is checked, for example spec file.
# @arg: $3... - the command to run inside the container.
# @stdout: the problem, if any.
# @exitcode: 0 if the check passed, 1 otherwise.
verify-data-check() {
    local run_dir what
    run_dir="${1}"
    what="${2}"
    shift 2
    if container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" "$@" >/dev/null 2>&1; then
        write-log "${run_dir}" build-data-copy "Check ${what}: ok"
        return 0
    fi
    write-log "${run_dir}" build-data-copy "Check ${what}: failed"
    echo "${what}: failed"
    return 1
}

# @description: Checks that the spec file and the source tree are in place and that no junk files are left.
# @arg: $1 - the run folder.
# @stdout: the problems, if any.
# @exitcode: 0 if all checks passed, 1 otherwise.
verify-data-in-builder() {
    local run_dir raw_input leftover rc
    run_dir="${1}"
    raw_input="/builder/input/podshift-${TST_SOURCE_BRANCH}"
    rc=0
    verify-data-check "${run_dir}" "spec file in SOURCES" test -f /builder/output/SOURCES/podshift.spec || rc=1
    verify-data-check "${run_dir}" "source tree" test -d "${raw_input}/src" || rc=1
    verify-data-check "${run_dir}" "spec file in source tree" test -f "${raw_input}/podshift.spec" || rc=1
    leftover="$(container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" find "${raw_input}" -name .git -o -name .DS_Store -o -name .idea -o -name .run 2>/dev/null)"
    if [[ -z "${leftover}" ]]; then
        write-log "${run_dir}" build-data-copy "Check no junk files: ok"
    else
        write-log "${run_dir}" build-data-copy "Check no junk files: failed"
        echo "Junk files left:"
        echo "${leftover}"
        rc=1
    fi
    return "${rc}"
}
