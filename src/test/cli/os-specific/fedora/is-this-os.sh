#!/usr/bin/env bash
# @file: is-this-os.sh
# @source-dir: src/test/cli/os-specific/fedora
# @group: test
# @category: helper
# @description: Tells whether this computer runs Fedora.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads the ID from /etc/os-release, so it works on a bare machine.
# @exitcode: 0 if this is Fedora, 1 otherwise.
is-this-os() {
    [[ -r /etc/os-release ]] && grep -qx 'ID=fedora' /etc/os-release
}

# Executes only when run directly (bash is-this-os.sh)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && is-this-os
