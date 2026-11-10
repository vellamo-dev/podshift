#!/usr/bin/env bash
# @file: container-copy.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Copies a file or folder into a container.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies a host file or folder into a container.
# @arg: $1 - the host path.
# @arg: $2 - the target, as NAME:PATH.
# @exitcode: the exit code of the copy.
container-copy() {
    container copy "${1}" "${2}"
}
