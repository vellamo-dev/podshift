#!/usr/bin/env bash
# @file: logger.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/mocks
# @group: test
# @category: helper
# @description: Mock of logger that writes to COCKPIT_TEST_LOG and fails when COCKPIT_TEST_LOGGER_FAIL is 1.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
printf '%s\n' "$*" >> "${COCKPIT_TEST_LOG}"
if [[ "${COCKPIT_TEST_LOGGER_FAIL:-}" == "1" ]]; then
    exit 1
fi
exit 0
