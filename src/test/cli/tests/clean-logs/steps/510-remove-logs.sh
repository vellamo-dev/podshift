#!/usr/bin/env bash
# @file: 510-remove-logs.sh
# @source-dir: src/test/cli/tests/clean-logs/steps
# @group: test
# @category: step
# @description: Remove all logs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes everything in artifacts/logs, including this run's own folder.
# @details:
#   Writes no log.
# @arg: $1 - the run folder (not used, this test keeps no log).
# @stdout: how many entries were removed.
# @exitcode: 0 if removed, 1 otherwise.
remove-logs() {
    local count
    count="$(find artifacts/logs -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
    find artifacts/logs -mindepth 1 -maxdepth 1 -exec rm -rf {} + || return 1
    echo "NOTE: ${count} removed"
}
