#!/usr/bin/env bash
# @file: one_json.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Tells if the last output is exactly one JSON value.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Tells if the last output is exactly one JSON value.
one_json() {
    printf '%s' "${LAST_OUT}" | jq -e -s 'length == 1' >/dev/null 2>&1
}
