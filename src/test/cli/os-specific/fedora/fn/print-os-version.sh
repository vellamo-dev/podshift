#!/usr/bin/env bash
# @file: print-os-version.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Prints the name and version of Fedora.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Fedora version shown in the test header.
# @stdout: for example Fedora 45.
print-os-version() {
    printf 'Fedora %s\n' "$(sed -n 's/^VERSION_ID=//p' /etc/os-release 2>/dev/null | tr -d '"')"
}
