#!/usr/bin/env bash
# @file: print-deploy-skip.sh
# @source-dir: src/deployment/fn/utils
# @group: deployment
# @category: helper
# @description: Prints an indented [SKIP] status line for the current deployment step.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits an indented skip status for the current step.
# @arg: $1 - optional reason (defaults to "Skipped")
# @stdout: prints the [SKIP] line
print-deploy-skip() {
    local reason
    reason="${1:-Skipped}"
    echo -e "\t[SKIP] ${reason}"
}
