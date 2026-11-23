#!/usr/bin/env bash
# @file: still_alive.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Tells if a process is running and not a zombie.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Tells if a process is running and not a zombie.
still_alive() {
    local pid stat
    pid="${1}"
    stat="$(ps -o stat= -p "${pid}" 2>/dev/null | tr -d '[:space:]')"
    [[ -n "${stat}" && "${stat}" != Z* ]]
}
