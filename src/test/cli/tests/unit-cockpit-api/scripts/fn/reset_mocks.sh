#!/usr/bin/env bash
# @file: reset_mocks.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Empties the mock logs and sets the systemd-run mock back to fail.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Empties the mock logs and sets the systemd-run mock back to fail.
reset_mocks() {
    : >"${ARGV}"
    : >"${STDIN}"
    : >"${LOG}"
    rm -f "${CHILD}"
    MODE="fail"
    EMIT=""
    EMIT_RC="0"
    LOGGER_FAIL=""
}
