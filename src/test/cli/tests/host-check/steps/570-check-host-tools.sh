#!/usr/bin/env bash
# @file: 570-check-host-tools.sh
# @source-dir: src/test/cli/tests/host-check/steps
# @group: test
# @category: step
# @description: Host tools.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the tools the tests use are installed.
# @stdout: each missing tool and how to fix it.
# @arg: $1 - the run folder.
# @exitcode: 0 if all are found, 3 otherwise (cannot run here).
check-host-tools() {
    local run_dir tool rc
    run_dir="${1}"
    rc=0
    write-log "${run_dir}" host-check "Host tools: realpath date find mktemp glow"
    for tool in realpath date find mktemp glow; do
        command -v "${tool}" >/dev/null 2>&1 && continue
        echo "${tool} not found"
        echo "Fix: ${TST_INSTALL_CMD} ${tool}"
        rc=3
    done
    return "${rc}"
}
