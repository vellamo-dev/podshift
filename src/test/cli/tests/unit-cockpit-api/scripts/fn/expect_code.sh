#!/usr/bin/env bash
# @file: expect_code.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Checks the last run exited 0 with one JSON value and the wanted status code.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the last run exited 0 with one JSON value and the wanted status code.
expect_code() {
    local name want got
    name="${1}"
    want="${2}"
    if [[ "${LAST_RC}" -ne 0 ]]; then
        bad "${name}" "exit ${LAST_RC}, stderr=${LAST_ERR}"
        return 1
    fi
    if ! one_json; then
        bad "${name}" "stdout is not one JSON value"
        return 1
    fi
    got="$(field '.status.code')"
    if [[ "${got}" != "${want}" ]]; then
        bad "${name}" "code ${got}, want ${want}"
        return 1
    fi
    return 0
}
