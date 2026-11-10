#!/usr/bin/env bash
# @file: container-cli.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Runs the container tool of this platform (Apple container).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs container with the given arguments.
# @arg: $@ - the arguments, for example exec -u 0 NAME true.
# @exitcode: the exit code of container.
container-cli() {
    container "$@"
}
