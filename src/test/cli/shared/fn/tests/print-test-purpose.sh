#!/usr/bin/env bash
# @file: print-test-purpose.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Prints what a test is for: test or maintenance.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads what a test is for from the @purpose line in its main.sh.
# @arg: $1 - the test folder.
# @stdout: test or maintenance. test when there is no @purpose line.
print-test-purpose() {
    local purpose
    purpose="$(sed -n 's/^# @purpose: //p' "${1}/main.sh" | head -n 1)"
    printf '%s\n' "${purpose:-test}"
}
