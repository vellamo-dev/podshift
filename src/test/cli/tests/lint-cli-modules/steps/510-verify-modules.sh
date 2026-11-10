#!/usr/bin/env bash
# @file: 510-verify-modules.sh
# @source-dir: src/test/cli/tests/lint-cli-modules/steps
# @group: test
# @category: step
# @description: Verify CLI modules.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks every folder in cli/modules: a valid name, and a main.sh that passes bash -n.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each problem.
# @exitcode: 0 if all are fine, 2 if a module has a problem (PodShift problem).
verify-modules() {
    local run_dir modules_dir dir name count bad
    run_dir="${1}"
    modules_dir="${TST_PODSHIFT_DIR}/cli/modules"
    count=0
    bad=0
    if [[ ! -d "${modules_dir}" ]]; then
        echo "The folder ${modules_dir} was not found"
        return 2
    fi
    for dir in "${modules_dir}"/*/; do
        [[ -d "${dir}" ]] || continue
        name="$(basename "${dir}")"
        count=$((count + 1))
        if ! is-valid-cli-name "${name}"; then
            echo "DETAIL: ${name}: invalid name"
            bad=$((bad + 1))
        elif [[ ! -f "${dir}main.sh" ]]; then
            echo "DETAIL: ${name}: main.sh missing"
            bad=$((bad + 1))
        elif ! bash -n "${dir}main.sh" 2>/dev/null; then
            echo "DETAIL: ${name}: main.sh fails bash -n"
            bad=$((bad + 1))
        fi
    done
    write-log "${run_dir}" lint-cli-modules "Modules: ${count} checked, ${bad} with problems"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
