#!/usr/bin/env bash
# @file: health-render-tsv.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @unit-test: yes
# @description: Prints the health check report as TSV.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints one TSV line per check, then a verdict line.
# @arg: $1 - the result lines: group<TAB>id<TAB>title<TAB>status<TAB>detail.
# @arg: $2 - the verdict line from health-verdict.
# @arg: $3 - the caller: root, podshift, or other.
# @stdout: id<TAB>group<TAB>status<TAB>detail per check, then verdict<TAB>verdict<TAB>caller<TAB>issues<TAB>warnings<TAB>errors<TAB>skipped<TAB>notes.
# @exitcode: 0 always.
health-render-tsv() {
    local results verdict_line caller group id title status detail verdict passed issues warnings errors skipped notes
    results="${1}"
    verdict_line="${2}"
    caller="${3}"

    while IFS=$'\t' read -r group id title status detail; do
        printf '%s\t%s\t%s\t%s\n' "${id}" "${group}" "${status}" "${detail}"
    done <<< "${results}"

    IFS=$'\t' read -r verdict passed issues warnings errors skipped notes <<< "${verdict_line}"
    printf 'verdict\t%s\t%s\t%d\t%d\t%d\t%d\t%d\n' "${verdict}" "${caller}" "${issues}" "${warnings}" "${errors}" "${skipped}" "${notes}"
    return 0
}
