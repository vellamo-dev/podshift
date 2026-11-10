#!/usr/bin/env bash
# @file: 110-check-container-system.sh
# @source-dir: src/test/cli/tests/clean-containers/os-specific/mac/steps
# @group: test
# @category: step
# @description: Check Apple container system.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the Apple container system is running, since nothing can be listed or removed without it.
# @arg: $1 - the run folder.
# @stdout: the problem and how to fix it, if any.
# @exitcode: 0 if running, 3 otherwise (cannot run here).
check-container-system() {
    if container system status >/dev/null 2>&1; then
        return 0
    fi
    echo "The container system is not running"
    echo "Fix: run container system start"
    return 3
}
