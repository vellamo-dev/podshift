#!/usr/bin/env bash
# @file: field.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Prints one jq field of the last output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints one jq field of the last output.
field() {
    printf '%s' "${LAST_OUT}" | jq -r "${1}" 2>/dev/null
}
