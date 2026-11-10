#!/usr/bin/env bash
# @file: vm-exists.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Checks whether a VM exists.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether Lima has a VM with this name.
# @arg: $1 - the VM name.
# @exitcode: 0 if it exists, 1 otherwise.
vm-exists() {
    vm list --format '{{.Name}}' 2>/dev/null | grep -qx "${1}"
}
