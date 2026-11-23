#!/usr/bin/env bash
# @file: print-deploy-ok.sh
# @source-dir: src/deployment/fn/utils
# @group: deployment
# @category: helper
# @description: Prints an indented [OK] status line for the current deployment step.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits an indented success status for the current step.
# @arg: $1 - optional message (defaults to "Done")
# @stdout: prints the [OK] line
print-deploy-ok() {
    local message
    message="${1:-Done}"
    echo -e "\t[OK] ${message}"
}
