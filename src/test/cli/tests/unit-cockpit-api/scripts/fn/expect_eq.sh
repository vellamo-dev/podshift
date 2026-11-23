#!/usr/bin/env bash
# @file: expect_eq.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Counts a case as passed when two texts are equal, otherwise as failed with a reason.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Counts a case as passed when two texts are equal, otherwise as failed with a reason.
# @arg: $1 - the case name.
# @arg: $2 - the text the case got.
# @arg: $3 - the text it wants.
# @arg: $4 - optional reason for a failure; by default the two texts.
expect_eq() {
    if [[ "${2}" == "${3}" ]]; then
        ok "${1}"
    else
        bad "${1}" "${4:-got ${2}, want ${3}}"
    fi
}
