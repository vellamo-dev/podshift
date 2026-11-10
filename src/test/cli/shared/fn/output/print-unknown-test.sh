#!/usr/bin/env bash
# @file: print-unknown-test.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Tells that a test name is unknown and shows the tests there are.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints that a test is unknown, suggests similar names, and lists all tests that can run here.
# @details:
#   A similar name contains the given name, is contained in it, or is at most two typos away; these
#   are shown as "Did you mean".
# @arg: $1 - the cli folder.
# @arg: $2 - the OS, for example mac.
# @arg: $3 - the unknown test name, for example build-install-validate.
# @stderr: the message, the suggestions and the test list.
print-unknown-test() {
    local cli_dir os name test_dir candidate matches
    cli_dir="${1}"
    os="${2}"
    name="${3}"
    matches=""
    if [[ -n "${name}" ]]; then
        for test_dir in "${cli_dir}/tests"/*; do
            candidate="$(basename "${test_dir}")"
            validate-test "${test_dir}" "${os}" 2>/dev/null || continue
            [[ "${candidate}" == *"${name}"* || "${name}" == *"${candidate}"* ]] \
                || (( $(text-distance "${name}" "${candidate}") <= 2 )) \
                || continue
            matches="${matches:+${matches}, }${candidate}"
        done
    fi
    {
        echo "Unknown test: ${name:-<none>}"
        [[ -z "${matches}" ]] || echo "Did you mean: ${matches}"
        echo
        print-test-list "${cli_dir}" "${os}"
    } >&2
}
