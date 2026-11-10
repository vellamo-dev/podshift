#!/usr/bin/env bash
# @file: 510-verify-builder-container.sh
# @source-dir: src/test/cli/tests/build-container-start/steps
# @group: test
# @category: step
# @description: Verify RPM builder container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks one thing inside the RPM builder container and logs the result.
# @arg: $1 - the run folder.
# @arg: $2 - what is checked, for example rpmbuild.
# @arg: $3... - the command to run inside the container.
# @stdout: the problem, if any.
# @exitcode: 0 if the check passed, 1 otherwise.
verify-builder-check() {
    local run_dir what
    run_dir="${1}"
    what="${2}"
    shift 2
    if container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" "$@" >/dev/null 2>&1; then
        write-log "${run_dir}" build-container-start "Check ${what}: ok"
        return 0
    fi
    write-log "${run_dir}" build-container-start "Check ${what}: failed"
    echo "${what}: failed"
    return 1
}

# @description: Checks that the RPM builder container runs and has what the build needs.
# @arg: $1 - the run folder.
# @stdout: the problems, if any.
# @exitcode: 0 if all checks passed, 1 otherwise.
verify-builder-container() {
    local run_dir rc
    run_dir="${1}"
    container-running "${TST_RPM_BUILDER_CNT}" || { echo "The container ${TST_RPM_BUILDER_CNT} is not running"; return 1; }
    rc=0
    verify-builder-check "${run_dir}" "exec" true || rc=1
    verify-builder-check "${run_dir}" "rpmbuild" rpmbuild --version || rc=1
    verify-builder-check "${run_dir}" "tree" tree --version || rc=1
    verify-builder-check "${run_dir}" "/share mounted" test -d /share || rc=1
    return "${rc}"
}
