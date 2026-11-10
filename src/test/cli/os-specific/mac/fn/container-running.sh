#!/usr/bin/env bash
# @file: container-running.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Checks whether a container is running.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether a container is running.
# @arg: $1 - the container name.
# @exitcode: 0 if running, 1 otherwise.
container-running() {
    container ls 2>/dev/null | grep -qw "${1}"
}
