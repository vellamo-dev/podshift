#!/usr/bin/env bash
# @file: print-step-warn.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints an indented [WARN] status line for the current step.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_822945F67449:-}" ]]; then
    DIR_822945F67449="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_822945F67449
fi

# @description: Emits an indented warning for the current step.
# @arg: $1 - warning message (a trailing period is stripped)
# @stderr: prints the [WARN] line, yellow when stderr is a terminal
print-step-warn() {
    local message
    message="${1}"
    # Keep status lines punctuation-free: strip one trailing period.
    message="${message%.}"
    # shellcheck source=is-interactive-output.sh
    declare -F is-interactive-output >/dev/null || source "${DIR_822945F67449}/is-interactive-output.sh"
    if is-interactive-output 2; then
        printf '\t\033[1;33m[WARN] %s\033[0m\n' "${message}" >&2
    else
        printf '\t[WARN] %s\n' "${message}" >&2
    fi
}
