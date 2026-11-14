#!/usr/bin/env bash
# @file: 520-verify-unit-tests-used.sh
# @source-dir: src/test/cli/tests/lint-pure-functions/steps
# @group: test
# @category: step
# @description: Verify unit tests used.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every bats file belongs to a file tagged @unit-test: yes.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each bats file without a tagged file.
# @exitcode: 0 if all are used, 2 otherwise (PodShift problem).
verify-unit-tests-used() {
    local run_dir file name count bad
    run_dir="${1}"
    count=0
    bad=0
    for file in "${TST_UNIT_DIR}"/*.bats; do
        [[ -f "${file}" ]] || continue
        name="$(basename -- "${file}" .bats)"
        count=$((count + 1))
        if ! grep -rl --include="${name}.sh" '^# @unit-test: yes' "${TST_PODSHIFT_DIR}" src/test/cli/shared/fn | grep -q .; then
            echo "DETAIL: ${name}.bats: no ${name}.sh tagged @unit-test: yes"
            bad=$((bad + 1))
        fi
    done
    write-log "${run_dir}" lint-pure-functions "Bats files: ${count} checked, ${bad} unused"
    echo "NOTE: ${count} bats files, ${bad} unused"
    (( bad == 0 )) || return 2
}
