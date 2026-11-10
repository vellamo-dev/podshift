#!/usr/bin/env bash
# @file: 510-verify-container-system.sh
# @source-dir: src/test/cli/tests/host-container-start/os-specific/mac/steps
# @group: test
# @category: step
# @description: Verify Apple container system.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the Apple container system is running.
# @arg: $1 - the run folder.
# @stdout: the problem and how to fix it, if any.
# @exitcode: 0 if running, 3 otherwise (cannot run here).
verify-container-system() {
    local run_dir
    run_dir="${1}"
    if container system status >/dev/null 2>&1; then
        write-log "${run_dir}" host-container-start "Apple container system: running"
        return 0
    fi
    write-log "${run_dir}" host-container-start "Apple container system: not running"
    echo "The container system is not running"
    echo "Fix: run container system start"
    return 3
}
