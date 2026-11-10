#!/usr/bin/env bash
# @file: print-test-list.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the tests that can run on this computer.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the tests that can run on this computer with their titles, read from the main.sh files.
# @details:
#   The maintenance tests are shown in their own list.
# @arg: $1 - the cli folder.
# @arg: $2 - the OS, for example mac.
# @stdout: the Tests list, and the Maintenance list when there is one.
print-test-list() {
    local cli_dir os test_dir name tests maintenance width
    cli_dir="${1}"
    os="${2}"
    tests=""
    maintenance=""
    width=0
    for test_dir in "${cli_dir}/tests"/*; do
        name="$(basename "${test_dir}")"
        validate-test "${test_dir}" "${os}" 2>/dev/null || continue
        (( ${#name} <= width )) || width="${#name}"
        if [[ "$(print-test-purpose "${test_dir}")" == "maintenance" ]]; then
            maintenance="${maintenance}${name}|$(print-test-title "${test_dir}")"$'\n'
        else
            tests="${tests}${name}|$(print-test-title "${test_dir}")"$'\n'
        fi
    done
    printf 'Tests:\n'
    printf '%s' "${tests}" | awk -F '|' -v w="${width}" '{ printf "    %-*s   %s\n", w, $1, $2 }'
    if [[ -n "${maintenance}" ]]; then
        printf '\nMaintenance:\n'
        printf '%s' "${maintenance}" | awk -F '|' -v w="${width}" '{ printf "    %-*s   %s\n", w, $1, $2 }'
    fi
}
