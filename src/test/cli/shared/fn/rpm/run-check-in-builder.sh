#!/usr/bin/env bash
# @file: run-check-in-builder.sh
# @source-dir: src/test/cli/shared/fn/rpm
# @group: test
# @category: helper
# @description: Runs one check inside the RPM builder container and logs the result.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs a shell command inside the RPM builder container.
# @details:
#   Logs "Check <what>: ok" or "failed" to <log_name>.log.
# @arg: $1 - the run folder.
# @arg: $2 - the log name, usually the test name.
# @arg: $3 - the exit code to return if the check fails.
# @arg: $4 - what is checked, for example binary RPM built.
# @arg: $5 - the shell command to run inside the container.
# @stdout: the problem, if any.
# @exitcode: 0 if the check passed, $3 otherwise.
run-check-in-builder() {
    local run_dir log_name fail_rc what
    run_dir="${1}"
    log_name="${2}"
    fail_rc="${3}"
    what="${4}"
    if container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash -c "${5}" >/dev/null 2>&1; then
        write-log "${run_dir}" "${log_name}" "Check ${what}: ok"
        return 0
    fi
    write-log "${run_dir}" "${log_name}" "Check ${what}: failed"
    echo "${what}: failed"
    return "${fail_rc}"
}
