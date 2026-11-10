#!/usr/bin/env bash
# @file: 540-check-lima.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/mac/steps
# @group: test
# @category: step
# @description: Lima installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that Lima is installed, which runs the RPM installer VM.
# @arg: $1 - the run folder.
# @stdout: the problem and how to fix it, if any.
# @exitcode: 0 if installed, 3 otherwise (cannot run here).
check-lima() {
    local run_dir
    run_dir="${1}"
    write-log "${run_dir}" host-check "Lima: $(limactl --version 2>/dev/null || echo not found)"
    command -v limactl >/dev/null 2>&1 && return 0
    echo "limactl command not found"
    echo "Fix: ${TST_INSTALL_CMD} lima"
    return 3
}
