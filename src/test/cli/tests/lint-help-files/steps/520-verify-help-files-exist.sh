#!/usr/bin/env bash
# @file: 520-verify-help-files-exist.sh
# @source-dir: src/test/cli/tests/lint-help-files/steps
# @group: test
# @category: step
# @description: Verify every command has help.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every module and shortcut has a help file, doc/help/<name>.md or <name>.txt.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each command without help.
# @exitcode: 0 if all have help, 2 otherwise (PodShift problem).
verify-help-files-exist() {
    local run_dir help_dir name file count bad
    run_dir="${1}"
    help_dir="${TST_PODSHIFT_DIR}/doc/help"
    count=0
    bad=0
    while IFS=$'\t' read -r name file; do
        count=$((count + 1))
        if [[ ! -f "${help_dir}/${name}.md" && ! -f "${help_dir}/${name}.txt" ]]; then
            echo "DETAIL: ${name}: no help file"
            bad=$((bad + 1))
        fi
    done < <(podshift-command-list "${TST_PODSHIFT_DIR}")
    write-log "${run_dir}" lint-help-files "Help files: ${count} commands, ${bad} without help"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
