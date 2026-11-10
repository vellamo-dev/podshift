#!/usr/bin/env bash
# @file: 110-check-glow-installed.sh
# @source-dir: src/test/cli/tests/dev-cli-help-show-all/steps
# @group: test
# @category: step
# @description: glow installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that glow is installed.
# @details:
#   PodShift needs it to show Markdown help.
# @arg: $1 - the run folder.
# @stdout: NOTE with the path, or the problem and a Fix line.
# @exitcode: 0 if installed, 3 otherwise (cannot run here).
check-glow-installed() {
    if ! command -v glow >/dev/null 2>&1; then
        echo "glow not found. PodShift needs it to show Markdown help."
        echo "Fix: ${TST_INSTALL_CMD} glow"
        return 3
    fi
    echo "NOTE: $(command -v glow)"
}
