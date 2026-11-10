#!/usr/bin/env bash
# @file: 550-verify-command-descriptions.sh
# @source-dir: src/test/cli/tests/lint-help-files/steps
# @group: test
# @category: step
# @description: Verify command descriptions.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every module and shortcut has an @description tag.
# @details:
#   The main help shows its first sentence.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each command without a description.
# @exitcode: 0 if all have one, 2 otherwise (PodShift problem).
verify-command-descriptions() {
    local run_dir name file count bad
    run_dir="${1}"
    count=0
    bad=0
    while IFS=$'\t' read -r name file; do
        count=$((count + 1))
        if ! grep -q '^# @description: *[^ ]' "${file}"; then
            echo "DETAIL: ${name}: no @description"
            bad=$((bad + 1))
        fi
    done < <(podshift-command-list "${TST_PODSHIFT_DIR}")
    write-log "${run_dir}" lint-help-files "Descriptions: ${count} checked, ${bad} missing"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
