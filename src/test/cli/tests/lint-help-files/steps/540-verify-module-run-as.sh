#!/usr/bin/env bash
# @file: 540-verify-module-run-as.sh
# @source-dir: src/test/cli/tests/lint-help-files/steps
# @group: test
# @category: step
# @description: Verify module realms.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every module main.sh has an @run-as tag of any, podshift or root.
# @details:
#   The main help groups the modules by it.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each module with a missing or wrong tag.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-module-run-as() {
    local run_dir file name realm count bad
    run_dir="${1}"
    count=0
    bad=0
    for file in "${TST_PODSHIFT_DIR}"/cli/modules/*/main.sh; do
        [[ -f "${file}" ]] || continue
        name="$(basename -- "$(dirname -- "${file}")")"
        realm="$(sed -n 's/^# @run-as: *//p' "${file}" | head -n 1)"
        count=$((count + 1))
        case "${realm}" in
            any|podshift|root) ;;
            "") echo "DETAIL: ${name}: no @run-as tag"; bad=$((bad + 1)) ;;
            *)  echo "DETAIL: ${name}: @run-as is '${realm}', expected any, podshift or root"; bad=$((bad + 1)) ;;
        esac
    done
    write-log "${run_dir}" lint-help-files "Module realms: ${count} checked, ${bad} with problems"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
