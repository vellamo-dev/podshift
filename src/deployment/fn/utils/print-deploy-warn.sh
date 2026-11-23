#!/usr/bin/env bash
# @file: print-deploy-warn.sh
# @source-dir: src/deployment/fn/utils
# @group: deployment
# @category: helper
# @description: Prints an indented [WARN] status line for the current deployment step.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits an indented warning for the current step.
# @arg: $1 - warning message (a trailing period is stripped)
# @stderr: prints the [WARN] line, yellow when stderr is a terminal
print-deploy-warn() {
    local message
    message="${1}"
    # Keep status lines punctuation-free: strip one trailing period.
    message="${message%.}"
    if [[ -t 2 ]]; then
        printf '\t\033[1;33m[WARN] %s\033[0m\n' "${message}" >&2
    else
        printf '\t[WARN] %s\n' "${message}" >&2
    fi
}
