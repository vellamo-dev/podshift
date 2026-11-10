#!/usr/bin/env bash
# @file: print-warning.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints a warning message to stderr in bold yellow.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4D2B935528B8:-}" ]]; then
    DIR_4D2B935528B8="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4D2B935528B8
fi

# @description: Prints a warning message to stderr, in bold yellow when stderr is a terminal.
# @arg: $1 - warning message
# @stderr: prints the warning line.
print-warning() {
    local message
    message="${1}"
    # shellcheck source=is-interactive-output.sh
    declare -F is-interactive-output >/dev/null || source "${DIR_4D2B935528B8}/is-interactive-output.sh"
    if is-interactive-output 2; then
        printf '\033[1;33mWarning: %s\033[0m\n' "${message}" >&2
    else
        printf 'Warning: %s\n' "${message}" >&2
    fi
}
