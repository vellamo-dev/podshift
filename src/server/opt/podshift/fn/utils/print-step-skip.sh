#!/usr/bin/env bash
# @file: print-step-skip.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints an indented [SKIP] status line for the current step.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits an indented skip status for the current step.
# @arg: $1 - optional reason (defaults to "Skipped")
# @stdout: prints the [SKIP] line
print-step-skip() {
    local reason
    reason="${1:-Skipped}"
    echo -e "\t[SKIP] ${reason}"
}
