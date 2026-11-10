#!/usr/bin/env bash
# @file: 510-check-apple-silicon.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/mac/steps
# @group: test
# @category: step
# @description: Apple silicon.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that this Mac has Apple silicon.
# @stdout: the problem and how to fix it, if any.
# @arg: $1 - the run folder.
# @exitcode: 0 if Apple silicon, 3 otherwise (cannot run here).
check-apple-silicon() {
    local run_dir
    run_dir="${1}"
    write-log "${run_dir}" host-check "Apple silicon: $(uname -m)"
    [[ "$(uname -m)" == "arm64" ]] && return 0
    echo "Found $(uname -m)"
    echo "Fix: run the tests on a Mac with Apple silicon"
    return 3
}
