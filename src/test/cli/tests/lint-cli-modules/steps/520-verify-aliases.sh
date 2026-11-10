#!/usr/bin/env bash
# @file: 520-verify-aliases.sh
# @source-dir: src/test/cli/tests/lint-cli-modules/steps
# @group: test
# @category: step
# @description: Verify CLI aliases.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks every alias in cli/aliases.conf is valid and points to a real module.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each problem.
# @exitcode: 0 if all are fine, 2 if an alias has a problem (PodShift problem).
verify-aliases() {
    local run_dir cli_dir line short long count bad
    run_dir="${1}"
    cli_dir="${TST_PODSHIFT_DIR}/cli"
    count=0
    bad=0
    if [[ ! -f "${cli_dir}/aliases.conf" ]]; then
        echo "The file ${cli_dir}/aliases.conf was not found"
        return 2
    fi
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%%#*}"
        [[ -n "${line// /}" ]] || continue
        short="${line%%=*}"
        long="${line#*=}"
        count=$((count + 1))
        if ! is-valid-cli-name "${short}"; then
            echo "DETAIL: ${short}: invalid name"
            bad=$((bad + 1))
        elif [[ -d "${cli_dir}/modules/${short}" ]]; then
            echo "DETAIL: ${short}: same name as a module"
            bad=$((bad + 1))
        elif [[ ! -f "${cli_dir}/modules/${long}/main.sh" ]]; then
            echo "DETAIL: ${short}: points to missing module ${long}"
            bad=$((bad + 1))
        fi
    done < "${cli_dir}/aliases.conf"
    write-log "${run_dir}" lint-cli-modules "Aliases: ${count} checked, ${bad} with problems"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
