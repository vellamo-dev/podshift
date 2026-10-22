#!/usr/bin/env bash
# @file: require-admin.sh
# @dir: /opt/podshift/fn/utils
# @group: utils
# @description: Stops if the current user is not an administrator.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_741B4F57EA79:-}" ]]; then
    DIR_741B4F57EA79="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_741B4F57EA79
fi

# shellcheck source=./is-admin.sh
source "${DIR_741B4F57EA79}/is-admin.sh"

# @description: Returns 0 if admin; otherwise prints an error and returns 1.
# @exitcode: 0 if admin, 1 otherwise.
require-admin() {
    if ! is-admin; then
        echo "Unauthorised. Root privileges required." >&2
        return 1
    fi
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && require-admin
fi
