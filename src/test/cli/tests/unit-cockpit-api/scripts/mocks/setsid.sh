#!/usr/bin/env bash
# @file: setsid.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/mocks
# @group: test
# @category: helper
# @description: Mock of setsid, which macOS lacks: logs its first argument and runs the rest.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
printf 'setsid %s\n' "${1-}" >> "${COCKPIT_TEST_SETSID_LOG}"
[[ "${1-}" == "--wait" ]] && shift
exec "$@"
