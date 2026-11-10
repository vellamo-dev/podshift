#!/usr/bin/env bash
# @file: print-help.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the short help of run.sh.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints conf/help.txt.
# @details:
#   The {{TESTS}} line is replaced with the tests that can run on this computer and their titles,
#   read from the main.sh files.
# @arg: $1 - the cli folder.
# @arg: $2 - the OS, for example mac.
# @stdout: the help.
print-help() {
    local cli_dir os line
    cli_dir="${1}"
    os="${2}"
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" == "{{TESTS}}" ]]; then
            print-test-list "${cli_dir}" "${os}"
        else
            printf '%s\n' "${line}"
        fi
    done < "${cli_dir}/shared/conf/help.txt"
}
