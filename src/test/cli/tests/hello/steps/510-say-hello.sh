#!/usr/bin/env bash
# @file: 510-say-hello.sh
# @source-dir: src/test/cli/tests/hello/steps
# @group: test
# @category: step
# @description: Say hello.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the greeting.
# @stdout: Hello world!
# @arg: $1 - the run folder.
# @exitcode: 0 always.
say-hello() {
    local run_dir
    run_dir="${1}"
    write-log "${run_dir}" hello "Hello world!"
    echo "Hello world!"
}
