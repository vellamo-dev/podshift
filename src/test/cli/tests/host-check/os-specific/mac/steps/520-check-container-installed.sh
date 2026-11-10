#!/usr/bin/env bash
# @file: 520-check-container-installed.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/mac/steps
# @group: test
# @category: step
# @description: Apple container installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the Apple container tool is installed.
# @stdout: the problem and how to fix it, if any.
# @arg: $1 - the run folder.
# @exitcode: 0 if installed, 3 otherwise (cannot run here).
check-container-installed() {
    local run_dir
    run_dir="${1}"
    write-log "${run_dir}" host-check "Apple container: $(command -v container || echo not found)"
    command -v container >/dev/null 2>&1 && return 0
    echo "container command not found"
    echo "Fix: install it from https://github.com/apple/container/releases"
    return 3
}
