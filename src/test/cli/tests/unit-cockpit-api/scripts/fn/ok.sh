#!/usr/bin/env bash
# @file: ok.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Prints a PASS line and counts it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints a PASS line and counts it.
ok() {
    echo "DETAIL: PASS ${1}"
    PASS=$((PASS + 1))
}
