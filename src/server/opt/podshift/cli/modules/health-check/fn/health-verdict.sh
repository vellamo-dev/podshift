#!/usr/bin/env bash
# @file: health-verdict.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @unit-test: yes
# @description: Sums up all health check results into one verdict.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Counts the results and decides the overall verdict.
# @details:
#   With no results, the verdict is incomplete and all counts are 0.
# @arg: $1 - the result lines, one per check: group<TAB>id<TAB>title<TAB>status<TAB>detail.
# @stdout: one line: verdict<TAB>passed<TAB>issues<TAB>warnings<TAB>errors<TAB>skipped<TAB>notes.
# @exitcode: 0 always.
health-verdict() {
    local results group id title status detail passed issues warnings errors skipped notes verdict
    results="${1}"
    passed=0
    issues=0
    warnings=0
    errors=0
    skipped=0
    notes=0

    while IFS=$'\t' read -r group id title status detail; do
        # An empty line is not a result.
        [[ -n "${group}${id}${title}${status}${detail}" ]] || continue
        case "${status}" in
            OK)    passed=$((passed + 1)) ;;
            FAIL)  issues=$((issues + 1)) ;;
            INFO)  notes=$((notes + 1)) ;;
            WARN)  warnings=$((warnings + 1)) ;;
            SKIP)  skipped=$((skipped + 1)) ;;
            *)     errors=$((errors + 1)) ;;
        esac
    done <<< "${results}"

    verdict="healthy"
    (( warnings > 0 )) && verdict="needs-attention"
    (( issues > 0 )) && verdict="issues-found"
    (( errors > 0 )) && verdict="incomplete"
    # Nothing ran, so nothing is known.
    (( passed + issues + warnings + errors + skipped + notes == 0 )) && verdict="incomplete"

    printf '%s\t%d\t%d\t%d\t%d\t%d\t%d\n' "${verdict}" "${passed}" "${issues}" "${warnings}" "${errors}" "${skipped}" "${notes}"
    return 0
}
