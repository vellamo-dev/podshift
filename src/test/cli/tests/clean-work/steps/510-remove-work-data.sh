#!/usr/bin/env bash
# @file: 510-remove-work-data.sh
# @source-dir: src/test/cli/tests/clean-work/steps
# @group: test
# @category: step
# @description: Remove all agent work files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes everything in artifacts/work.
# @details:
#   The folder itself stays. Writes no log.
# @arg: $1 - the run folder (not used, this test keeps no log).
# @stdout: NOTE with how many entries were removed, or none found.
# @exitcode: 0 if removed, 1 otherwise.
remove-work-data() {
    local count
    count="$(find artifacts/work -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
    if (( count == 0 )); then
        echo "NOTE: none found"
        return 0
    fi
    find artifacts/work -mindepth 1 -maxdepth 1 -exec rm -rf {} + || return 1
    echo "NOTE: ${count} removed"
}
