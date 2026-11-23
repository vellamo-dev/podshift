#!/usr/bin/env bash
# @file: expect_contract.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Checks a value against a contract and counts the result.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks a value against a contract and counts the result.
expect_contract() {
    local name contract value want got
    name="${1}"
    contract="${2}"
    value="${3}"
    want="${4}"
    cockpit-validate-contract "${contract}" "${value}"
    got=$?
    if [[ "${got}" -eq "${want}" ]]; then
        ok "${name}"
    else
        bad "${name}" "rc ${got} want ${want}"
    fi
}
