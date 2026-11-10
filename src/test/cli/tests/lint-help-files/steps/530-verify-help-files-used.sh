#!/usr/bin/env bash
# @file: 530-verify-help-files-used.sh
# @source-dir: src/test/cli/tests/lint-help-files/steps
# @group: test
# @category: step
# @description: Verify no unused help files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every file in doc/help belongs to a command, or is one of the files the help itself uses.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each unused file.
# @exitcode: 0 if all are used, 2 otherwise (PodShift problem).
verify-help-files-used() {
    local run_dir file id names count bad
    run_dir="${1}"
    # podshift.txt is the main help, version.md is for --version, and note-env-var-conf.txt is shown after install.
    names=" podshift version note-env-var-conf $(podshift-command-list "${TST_PODSHIFT_DIR}" | cut -f 1 | xargs) "
    count=0
    bad=0
    for file in "${TST_PODSHIFT_DIR}"/doc/help/*; do
        [[ -f "${file}" ]] || continue
        id="$(basename -- "${file}")"
        id="${id%.*}"
        count=$((count + 1))
        if [[ "${names}" != *" ${id} "* ]]; then
            echo "DETAIL: $(basename -- "${file}"): no command with this name"
            bad=$((bad + 1))
        fi
    done
    write-log "${run_dir}" lint-help-files "Help files: ${count} files, ${bad} unused"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
