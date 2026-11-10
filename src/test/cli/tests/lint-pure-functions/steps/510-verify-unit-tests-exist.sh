#!/usr/bin/env bash
# @file: 510-verify-unit-tests-exist.sh
# @source-dir: src/test/cli/tests/lint-pure-functions/steps
# @group: test
# @category: step
# @description: Verify unit tests exist.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every PodShift file with an @unit-test tag says yes and has a matching <function>.bats file.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each file with a wrong tag or no bats file.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-unit-tests-exist() {
    local run_dir file name value count bad
    run_dir="${1}"
    count=0
    bad=0
    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        name="$(basename -- "${file}" .sh)"
        value="$(sed -n 's/^# @unit-test: *//p' "${file}" | head -n 1)"
        count=$((count + 1))
        if [[ "${value}" != "yes" ]]; then
            echo "DETAIL: ${name}: @unit-test is '${value}', expected yes"
            bad=$((bad + 1))
        elif [[ ! -f "${TST_UNIT_DIR}/${name}.bats" ]]; then
            echo "DETAIL: ${name}: no ${TST_UNIT_DIR}/${name}.bats"
            bad=$((bad + 1))
        fi
    done <<< "$(grep -rl --include='*.sh' '^# @unit-test:' "${TST_PODSHIFT_DIR}" | sort)"
    write-log "${run_dir}" lint-pure-functions "Tagged files: ${count} checked, ${bad} with problems"
    echo "NOTE: ${count} tagged, ${bad} not OK"
    (( bad == 0 )) || return 2
}
