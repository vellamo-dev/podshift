#!/usr/bin/env bash
# @file: print-test-header.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the title of one test.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the test title, marked with ▶.
# @details:
#   Interactive mode shows ▶ in bold magenta and the title in bold cyan.
# @arg: $1 - the output mode: interactive or plain. Plain has no colors.
# @arg: $2 - the test title, for example Checking host.
# @stdout: the test header.
print-test-header() {
    if [[ "${1}" == "interactive" ]]; then
        printf '\n\033[1;35m▶\033[0m \033[1;36m%s\033[0m\n' "${2}"
    else
        printf '\n▶ %s\n' "${2}"
    fi
}
