#!/usr/bin/env bash
# @file: 510-show-help-main.sh
# @source-dir: src/test/cli/tests/dev-cli-help-show/steps
# @group: test
# @category: step
# @description: Main help.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift-help with no name from the source folder and prints every line as DETAIL.
# @details:
#   It works like podshift --help and saves the output to help-show-main.log.
# @arg: $1 - the run folder.
# @stdout: NOTE with the line count, and the help as DETAIL lines.
# @exitcode: 0 if the help ran, 2 otherwise (PodShift problem).
show-help-main() {
    local run_dir log rc
    run_dir="${1}"
    log="${run_dir}/help-show-main.log"
    "${BASH}" -c 'source "${1}/fn/common/podshift-help.sh"; podshift-help ""' _ "${TST_PODSHIFT_DIR}" >"${log}" 2>&1
    rc=$?
    write-log "${run_dir}" dev-cli-help-show "Main help: exit ${rc}"
    [[ "${rc}" -eq 0 ]] || echo "podshift --help failed (exit ${rc})"
    echo "NOTE: $(wc -l <"${log}" | tr -d ' ') lines, saved in help-show-main.log"
    sed 's/^/DETAIL: /' "${log}"
    [[ "${rc}" -eq 0 ]] || return 2
}
