#!/usr/bin/env bash
# @file: cockpit-health-check-label.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Prints the human health-check verdict label, matching the CLI Result line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the human verdict label, matching the CLI Result line without the icon.
# @arg: $1 - the verdict line from health-verdict.
# @stdout: a label such as "Healthy (27 passed, 1 note)".
# @exitcode: 0 always.
cockpit-health-check-label() {
    local verdict passed issues warnings errors skipped notes state counts
    IFS=$'\t' read -r verdict passed issues warnings errors skipped notes <<< "${1}"
    passed="${passed:-0}"
    issues="${issues:-0}"
    warnings="${warnings:-0}"
    errors="${errors:-0}"
    skipped="${skipped:-0}"
    notes="${notes:-0}"
    case "${verdict}" in
        healthy)         state="Healthy" ;;
        needs-attention) state="Needs attention" ;;
        issues-found)    state="Issues found" ;;
        *)               state="Check incomplete" ;;
    esac
    counts=""
    (( passed > 0 ))    && counts="${passed} passed"
    (( issues == 1 ))   && counts="${counts:+${counts}, }1 issue"
    (( issues > 1 ))    && counts="${counts:+${counts}, }${issues} issues"
    (( warnings == 1 )) && counts="${counts:+${counts}, }1 warning"
    (( warnings > 1 ))  && counts="${counts:+${counts}, }${warnings} warnings"
    (( notes == 1 ))    && counts="${counts:+${counts}, }1 note"
    (( notes > 1 ))    && counts="${counts:+${counts}, }${notes} notes"
    (( errors == 1 ))   && counts="${counts:+${counts}, }1 check could not run"
    (( errors > 1 ))    && counts="${counts:+${counts}, }${errors} checks could not run"
    (( skipped > 0 ))   && counts="${counts:+${counts}, }${skipped} skipped"
    printf '%s (%s)\n' "${state}" "${counts}"
    return 0
}
