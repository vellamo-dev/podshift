#!/usr/bin/env bash
# @file: bad.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Prints a FAIL line with its reason and counts it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints a FAIL line with its reason and counts it.
bad() {
    # Each extra line of the reason gets its own DETAIL prefix, so ./test shows it.
    echo "DETAIL: FAIL ${1}: ${2//$'\n'/$'\n'DETAIL:   }"
    FAIL=$((FAIL + 1))
}
