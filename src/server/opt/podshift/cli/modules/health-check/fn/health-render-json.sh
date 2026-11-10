#!/usr/bin/env bash
# @file: health-render-json.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @unit-test: yes
# @description: Prints the health check report as JSON.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5DCECEF4D96B:-}" ]]; then
    DIR_5DCECEF4D96B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5DCECEF4D96B
fi

# @description: Prints the report as one JSON object: an array per group, then the verdict and counts.
# @arg: $1 - the result lines: group<TAB>id<TAB>title<TAB>status<TAB>detail.
# @arg: $2 - the verdict line from health-verdict.
# @arg: $3 - the caller: root, podshift, or other.
# @stdout: the JSON object.
# @exitcode: 0 always.
health-render-json() {
    local results verdict_line caller group id title status detail prev_group verdict passed issues warnings errors skipped notes
    results="${1}"
    verdict_line="${2}"
    caller="${3}"
    # shellcheck source=../../../../fn/utils/json-q.sh
    declare -F json-q >/dev/null || source "${DIR_5DCECEF4D96B}/../../../../fn/utils/json-q.sh"

    printf '{'
    prev_group=""
    while IFS=$'\t' read -r group id title status detail; do
        if [[ -z "${prev_group}" ]]; then
            printf '%s:[' "$(json-q "${group}")"
        elif [[ "${group}" != "${prev_group}" ]]; then
            printf '],%s:[' "$(json-q "${group}")"
        else
            printf ','
        fi
        prev_group="${group}"
        printf '{"id":%s,"status":%s,"detail":%s}' "$(json-q "${id}")" "$(json-q "${status}")" "$(json-q "${detail}")"
    done <<< "${results}"
    [[ -n "${prev_group}" ]] && printf '],'

    IFS=$'\t' read -r verdict passed issues warnings errors skipped notes <<< "${verdict_line}"
    printf '"verdict":%s,"caller":%s,"passed":%d,"issues":%d,"warnings":%d,"errors":%d,"skipped":%d,"notes":%d}\n' \
        "$(json-q "${verdict}")" "$(json-q "${caller}")" "${passed}" "${issues}" "${warnings}" "${errors}" "${skipped}" "${notes}"
    return 0
}
