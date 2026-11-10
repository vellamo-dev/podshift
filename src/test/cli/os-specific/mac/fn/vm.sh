#!/usr/bin/env bash
# @file: vm.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Runs a Lima command.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs limactl with stdin from /dev/null, so it never waits for input.
# @arg: $@ - the limactl arguments.
# @stdout: the command output.
# @exitcode: the command's exit code.
vm() {
    limactl "$@" </dev/null
}
