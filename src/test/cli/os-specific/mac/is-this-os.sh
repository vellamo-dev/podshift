#!/usr/bin/env bash
# @file: is-this-os.sh
# @source-dir: src/test/cli/os-specific/mac
# @group: test
# @category: helper
# @description: Tells whether this computer is a Mac.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the kernel name with uname, so it works on a bare machine.
# @exitcode: 0 if this is a Mac, 1 otherwise.
is-this-os() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Executes only when run directly (bash is-this-os.sh)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && is-this-os
