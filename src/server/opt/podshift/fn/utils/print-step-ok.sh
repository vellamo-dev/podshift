#!/usr/bin/env bash
# @file: print-step-ok.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints an indented [OK] status line for the current step.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits an indented success status for the current step.
# @arg: $1 - optional message (defaults to "Done")
# @stdout: prints the [OK] line
print-step-ok() {
    local message
    message="${1:-Done}"
    echo -e "\t[OK] ${message}"
}
