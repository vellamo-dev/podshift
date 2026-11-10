#!/usr/bin/env bash
# @file: create-run-folder.sh
# @source-dir: src/test/cli/shared/fn/log
# @group: test
# @category: helper
# @description: Creates the run folder and its start.log.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Picks the next free run ID (YYYYMMDD-HHMM-NNN), creates artifacts/logs/<run-id>/, and writes one line to start.log.
# @arg: $1 - the repository root.
# @arg: $2 - the test name, for example hello.
# @arg: $3 - the environment, for example macOS 27.0.1.
# @arg: $4 - the output mode and reason, for example plain (no terminal).
# @stdout: the full path of the run folder.
# @exitcode: 0 if created, 1 otherwise.
create-run-folder() {
    local repo_root test_name environment output stamp n run_id run_dir
    repo_root="${1}"
    test_name="${2}"
    environment="${3}"
    output="${4}"
    stamp="$(date +%Y%m%d-%H%M)"
    mkdir -p "${repo_root}/artifacts/logs" || return 1
    for ((n = 1; n <= 999; n++)); do
        run_id="${stamp}-$(printf '%03d' "${n}")"
        run_dir="${repo_root}/artifacts/logs/${run_id}"
        mkdir "${run_dir}" 2>/dev/null && break
    done
    [[ -d "${run_dir}" ]] || return 1
    printf '%s %s %s %s %s\n' "${run_id}" "${test_name}" "${environment}" "${output}" "$(date +%Y-%m-%dT%H:%M:%S%z)" >"${run_dir}/start.log"
    printf '%s\n' "${run_dir}"
}
