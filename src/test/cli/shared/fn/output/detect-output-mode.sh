#!/usr/bin/env bash
# @file: detect-output-mode.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Decides whether test output is interactive (spinner, timer, colors) or plain, and why.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the output mode and the reason for it.
# @details:
#   The first match wins: the --plain flag, PODSHIFT_PLAIN=true or false, NO_COLOR set, CI set,
#   TERM dumb or empty, stdout not a terminal. Otherwise the output is interactive.
# @arg: $1 - yes if the run's stdout is a terminal, no otherwise. The caller checks it, because inside $(...) stdout is never a terminal.
# @arg: $2 - yes if --plain was given, no otherwise.
# @stdout: the mode and reason, for example plain (no terminal) or interactive (terminal).
detect-output-mode() {
    if [[ "${2}" == "yes" ]]; then
        echo "plain (--plain)"
    elif [[ "${PODSHIFT_PLAIN:-}" == "true" ]]; then
        echo "plain (PODSHIFT_PLAIN=true)"
    elif [[ "${PODSHIFT_PLAIN:-}" == "false" ]]; then
        echo "interactive (PODSHIFT_PLAIN=false)"
    elif [[ -n "${NO_COLOR+set}" ]]; then
        echo "plain (NO_COLOR set)"
    elif [[ -n "${CI+set}" ]]; then
        echo "plain (CI set)"
    elif [[ -z "${TERM:-}" ]]; then
        echo "plain (TERM is empty)"
    elif [[ "${TERM}" == "dumb" ]]; then
        echo "plain (TERM is dumb)"
    elif [[ "${1}" != "yes" ]]; then
        echo "plain (no terminal)"
    else
        echo "interactive (terminal)"
    fi
}
