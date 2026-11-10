#!/usr/bin/env bash
# @file: 110-start-container-system.sh
# @source-dir: src/test/cli/tests/host-container-start/os-specific/mac/steps
# @group: test
# @category: step
# @description: Start Apple container system.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Starts the Apple container system if it is not already running.
# @arg: $1 - the run folder.
# @stdout: NOTE already running or started, or the problem and how to fix it.
# @exitcode: 0 if running or started, 3 if it could not be started (cannot run here).
start-container-system() {
    local run_dir
    run_dir="${1}"
    if container system status >/dev/null 2>&1; then
        write-log "${run_dir}" host-container-start "Apple container system: already running"
        echo "NOTE: already running"
        return 0
    fi
    if container system start; then
        write-log "${run_dir}" host-container-start "Apple container system: started"
        echo "NOTE: started"
        return 0
    fi
    write-log "${run_dir}" host-container-start "Apple container system: could not start"
    echo "The container system could not be started"
    echo "Fix: run container system start and check its output"
    return 3
}
