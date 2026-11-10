#!/usr/bin/env bash
# @file: print-verdict.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the verdict of one test.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the verdict for a test exit code.
# @arg: $1 - the output mode: interactive or plain. Plain has no colors.
# @arg: $2 - the test exit code: 0 passed, 1 test error, 2 product failed, 3 cannot run here.
# @arg: $3 - optional text that replaces the standard one.
# @stdout: the verdict.
print-verdict() {
    local mode rc icon color text
    mode="${1}"
    rc="${2}"
    case "${rc}" in
        0) icon="✔"; color=32; text="Passed" ;;
        2) icon="✘"; color=31; text="Failed: PodShift problem. See the failed steps above." ;;
        3) icon="✘"; color=31; text="Cannot run here. Fix the problems above and run again." ;;
        *) icon="⚠"; color=33; text="Error: test or environment problem. Check the logs." ;;
    esac
    [[ "${mode}" != "interactive" ]] || icon=$'\033['"${color}"'m'"${icon}"$'\033[0m'
    printf '\n    Verdict:\n        %s %s\n' "${icon}" "${3:-${text}}"
}
