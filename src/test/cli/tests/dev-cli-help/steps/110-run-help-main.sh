#!/usr/bin/env bash
# @file: 110-run-help-main.sh
# @source-dir: src/test/cli/tests/dev-cli-help/steps
# @group: test
# @category: step
# @description: Run main help.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift-help with no name from the source folder, like podshift --help, and saves the output to help-main.log.
# @details:
#   It must exit 0, start with the head line, end with the closing line, and have no {{commands}}
#   left.
# @arg: $1 - the run folder.
# @stdout: NOTE with the line count, or the problem.
# @exitcode: 0 if fine, 2 otherwise (PodShift problem).
run-help-main() {
    local run_dir log rc
    run_dir="${1}"
    log="${run_dir}/help-main.log"
    "${BASH}" -c 'source "${1}/fn/common/podshift-help.sh"; podshift-help ""' _ "${TST_PODSHIFT_DIR}" >"${log}" 2>&1
    rc=$?
    write-log "${run_dir}" dev-cli-help "Main help: exit ${rc}, $(wc -l <"${log}" | tr -d ' ') lines"
    if [[ "${rc}" -ne 0 ]]; then
        echo "podshift --help failed (exit ${rc}), see help-main.log"
        tail -n 3 "${log}" | sed 's/^/DETAIL: /'
        return 2
    fi
    if [[ "$(head -n 1 "${log}")" != "podshift: "* ]]; then
        echo "The main help does not start with 'podshift: '"
        return 2
    fi
    if [[ "$(tail -n 1 "${log}")" != "See 'podshift --help <command>' for details." ]]; then
        echo "The main help does not end with the closing line"
        return 2
    fi
    if grep -q '{{commands}}' "${log}"; then
        echo "The main help still has a {{commands}} line"
        return 2
    fi
    echo "NOTE: $(wc -l <"${log}" | tr -d ' ') lines"
}
