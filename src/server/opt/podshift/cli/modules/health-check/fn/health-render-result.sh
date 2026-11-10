#!/usr/bin/env bash
# @file: health-render-result.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @unit-test: yes
# @description: Prints the overall health result for people.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_2C7073C1F2DB:-}" ]]; then
    DIR_2C7073C1F2DB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_2C7073C1F2DB
fi

# @description: Prints the Result block: an icon, the state in words and the counts.
# @arg: $1 - the verdict line from health-verdict.
# @stdout: the Result block.
# @exitcode: 0 always.
health-render-result() {
    local verdict passed issues warnings errors skipped notes state icon counts
    IFS=$'\t' read -r verdict passed issues warnings errors skipped notes <<< "${1}"
    case "${verdict}" in
        healthy)         state="Healthy";          icon="OK" ;;
        needs-attention) state="Needs attention";  icon="WARN" ;;
        issues-found)    state="Issues found";     icon="FAIL" ;;
        *)               state="Check incomplete"; icon="ERROR" ;;
    esac
    counts=""
    (( passed > 0 ))    && counts="${passed} passed"
    (( issues == 1 ))   && counts="${counts:+${counts}, }1 issue"
    (( issues > 1 ))    && counts="${counts:+${counts}, }${issues} issues"
    (( warnings == 1 )) && counts="${counts:+${counts}, }1 warning"
    (( warnings > 1 ))  && counts="${counts:+${counts}, }${warnings} warnings"
    (( notes == 1 ))    && counts="${counts:+${counts}, }1 note"
    (( notes > 1 ))     && counts="${counts:+${counts}, }${notes} notes"
    (( errors == 1 ))   && counts="${counts:+${counts}, }1 check could not run"
    (( errors > 1 ))    && counts="${counts:+${counts}, }${errors} checks could not run"
    (( skipped > 0 ))   && counts="${counts:+${counts}, }${skipped} skipped"
    # shellcheck source=../../../../fn/utils/paint.sh
    declare -F paint >/dev/null || source "${DIR_2C7073C1F2DB}/../../../../fn/utils/paint.sh"
    # shellcheck source=health-icon.sh
    declare -F health-icon >/dev/null || source "${DIR_2C7073C1F2DB}/health-icon.sh"
    printf '\n    Result:\n        %s %s (%s)\n' "$(health-icon "${icon}")" "$(paint bold "${state}")" "${counts}"
    return 0
}
