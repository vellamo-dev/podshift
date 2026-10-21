#!/usr/bin/env bash
# @file: print-step.sh
# @dir: src/deployment/fn/utils
# @group: deployment
# @description: Emits section headers tagged with the step id, plus indented [OK]/[WARN]/[SKIP] status.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits a section header tagged with the step id.
# @param: $1 - step tag (e.g. "PS-DP-DRS")
# @param: $2 - header message
# @stdout: prints the tagged header line
print-step-header() {
    local tag message
    tag="${1}"
    message="${2}"
    echo -e "\n[${tag}] ${message}"
}

# @description: Emits an indented warning for the current step.
# @param: $1 - warning message (a trailing period is stripped)
# @stderr: prints the yellow [WARN] line
print-step-warn() {
    local message
    message="${1}"
    # Keep status lines punctuation-free: strip one trailing period.
    message="${message%.}"
    echo -e "\t\033[1;33m[WARN] ${message}\033[0m" >&2
}

# @description: Emits an indented skip status for the current step.
# @param: $1 - optional reason (defaults to "Skipped")
# @stdout: prints the [SKIP] line
print-step-skip() {
    local reason
    reason="${1:-Skipped}"
    echo -e "\t[SKIP] ${reason}"
}

# @description: Emits an indented success status for the current step.
# @param: $1 - optional message (defaults to "Done")
# @stdout: prints the [OK] line
print-step-ok() {
    local message
    message="${1:-Done}"
    echo -e "\t[OK] ${message}"
}
