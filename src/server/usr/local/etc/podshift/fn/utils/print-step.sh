#!/usr/bin/env bash
# @file: print-step.sh
# @dir: /usr/local/etc/podshift/fn/utils
# @group: utils
# @description: Emits section headers tagged with the step id, plus indented [OK]/[WARN] status.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# Emits a section header for the current step.
print-step-header() {
    echo -e "\n[${step_prefix}-${step_id}] ${1}"
}

# Emits a warning for the current step (indented, yellow, to stderr).
print-step-warn() {
    echo -e "\t\033[1;33m[WARN] ${1}\033[0m" >&2
}

# Emits a skip status for the current step (indented).
# $1 = optional reason (defaults to "Skipped").
print-step-skip() {
    echo -e "\t[SKIP] ${1:-Skipped}"
}

# Emits the success status for the current step (indented).
# $1 = optional message (defaults to "Done").
print-step-ok() {
    echo -e "\t[OK] ${1:-Done}"
}
