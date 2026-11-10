#!/usr/bin/env bash
# @file: health-render-row.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Prints one health check result for people.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_DA5ABE72CFE4:-}" ]]; then
    DIR_DA5ABE72CFE4="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DA5ABE72CFE4
fi

# @description: Prints the icon, title and detail of one check, plus its Fix line on warning or failure.
# @arg: $1 - the result line: group<TAB>id<TAB>title<TAB>status<TAB>detail.
# @arg: $2 - path to the check script, for its @fix tag.
# @stdout: the check line, and an optional Fix line under it.
# @exitcode: 0 always.
health-render-row() {
    local line script group id title status detail text fix
    line="${1}"
    script="${2}"
    IFS=$'\t' read -r group id title status detail <<< "${line}"
    text="${title}: ${detail}"
    # shellcheck source=../../../../fn/utils/paint.sh
    declare -F paint >/dev/null || source "${DIR_DA5ABE72CFE4}/../../../../fn/utils/paint.sh"
    [[ "${status}" == "SKIP" ]] && text="$(paint dim "${text}")"
    # shellcheck source=health-icon.sh
    declare -F health-icon >/dev/null || source "${DIR_DA5ABE72CFE4}/health-icon.sh"
    printf '        %s %s\n' "$(health-icon "${status}")" "${text}"
    case "${status}" in
        INFO|WARN|FAIL)
            fix="$(grep -m1 '^# @fix:' "${script}" 2>/dev/null | sed 's/^# @fix: //')"
            [[ -n "${fix}" ]] && printf '          %s %s\n' "$(paint dim 'Fix:')" "${fix}"
            ;;
    esac
    return 0
}
