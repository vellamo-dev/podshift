#!/usr/bin/env bash
# @file: vm-running.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Checks whether a VM is running.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether Lima reports the VM as running.
# @arg: $1 - the VM name.
# @exitcode: 0 if running, 1 otherwise.
vm-running() {
    [[ "$(vm list --format '{{.Status}}' "${1}" 2>/dev/null)" == "Running" ]]
}
