#!/usr/bin/env bash
# @file: list-test-needs.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Lists the tests named in a test's @needs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the tests named in a test's @needs, in the order written.
# @arg: $1 - path of the test folder.
# @stdout: one test name per line.
list-test-needs() {
    local need
    for need in $(sed -n 's/^# @needs: //p' "${1}/main.sh"); do
        printf '%s\n' "${need}"
    done
}
