#!/usr/bin/env bash
# @file: health-icon.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Prints the status icon of one health check.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3D57253A9314:-}" ]]; then
    DIR_3D57253A9314="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3D57253A9314
fi

# @description: Prints the status icon, colored when PODSHIFT_OUTPUT is interactive.
# @arg: $1 - status: OK, WARN, FAIL, ERROR or SKIP.
# @stdout: the icon.
# @exitcode: 0 always.
health-icon() {
    local status
    status="${1}"
    # shellcheck source=../../../../fn/utils/paint.sh
    declare -F paint >/dev/null || source "${DIR_3D57253A9314}/../../../../fn/utils/paint.sh"
    case "${status}" in
        OK)    paint ok '✔' ;;
        INFO)  paint info 'ℹ' ;;
        WARN)  paint warn '⚠' ;;
        FAIL)  paint fail '✘' ;;
        ERROR) paint fail '!' ;;
        SKIP)  paint dim '·' ;;
        *)     printf '?' ;;
    esac
}
