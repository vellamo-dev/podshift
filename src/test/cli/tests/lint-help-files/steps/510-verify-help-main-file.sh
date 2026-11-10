#!/usr/bin/env bash
# @file: 510-verify-help-main-file.sh
# @source-dir: src/test/cli/tests/lint-help-files/steps
# @group: test
# @category: step
# @description: Verify main help file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that doc/help/podshift.txt exists and has exactly one {{commands}} line.
# @arg: $1 - the run folder.
# @stdout: a DETAIL line for the problem.
# @exitcode: 0 if fine, 2 otherwise (PodShift problem).
verify-help-main-file() {
    local run_dir file count
    run_dir="${1}"
    file="${TST_PODSHIFT_DIR}/doc/help/podshift.txt"
    if [[ ! -f "${file}" ]]; then
        echo "The main help file is missing: ${file#"${TST_PODSHIFT_DIR}/"}"
        return 2
    fi
    count="$(grep -cx '{{commands}}' "${file}")"
    write-log "${run_dir}" lint-help-files "Main help: ${count} {{commands}} lines"
    if [[ "${count}" -ne 1 ]]; then
        echo "podshift.txt has ${count} {{commands}} lines, expected 1"
        return 2
    fi
}
