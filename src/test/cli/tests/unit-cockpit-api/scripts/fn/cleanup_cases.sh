#!/usr/bin/env bash
# @file: cleanup_cases.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Stops a leftover mocked child and removes the work folders.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops a leftover mocked child and removes the work folders.
cleanup_cases() {
    local pid
    if [[ -f "${CHILD}" ]]; then
        pid="$(cat "${CHILD}" 2>/dev/null || true)"
        if [[ -n "${pid}" ]]; then
            kill -KILL "${pid}" 2>/dev/null || true
        fi
    fi
    rm -rf "${WORK}" "${CASES_WORK}/broken-ping" "${CASES_WORK}/retired-ping"
}
