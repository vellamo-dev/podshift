#!/usr/bin/env bash
# @file: expect_status.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Counts a case as passed when a check's exit status is 0, otherwise as failed with a reason.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Counts a case as passed when the given exit status is 0, otherwise as failed with the reason.
# @details:
#   For a check that is not one text compared with another: run the check on its own line, then
#   pass its status, for example `[[ -s "${log}" ]]` and then `expect_status "log-written" $? "empty"`.
#   To compare two texts, use expect_eq. The reason is worked out before the call, so a reason that
#   runs a command, such as $(cat "${log}"), stays in an if/ok/else/bad block.
# @arg: $1 - the case name.
# @arg: $2 - the exit status of the check.
# @arg: $3 - the reason shown on a failure.
expect_status() {
    if [[ "${2}" -eq 0 ]]; then
        ok "${1}"
    else
        bad "${1}" "${3}"
    fi
}
