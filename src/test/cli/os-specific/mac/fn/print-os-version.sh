#!/usr/bin/env bash
# @file: print-os-version.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Prints the name and version of macOS.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the macOS version shown in the test header.
# @stdout: for example macOS 27.0.1.
print-os-version() {
    printf 'macOS %s\n' "$(sw_vers -productVersion 2>/dev/null || echo unknown)"
}
