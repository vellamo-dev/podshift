#!/usr/bin/env bash
# @file: list-test-steps.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Lists a test's step files in run order.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Lists a test's steps in number order: its steps/ folder plus the os-specific/<os>/steps/ folder.
# @details:
#   An OS step with the same file name replaces the generic one.
# @arg: $1 - path of the test folder.
# @arg: $2 - the platform name, for example mac.
# @stdout: one step file path per line.
# @stderr: two different steps that share a number.
# @exitcode: 0 if the list is valid, 1 otherwise.
list-test-steps() {
    local test_dir os step
    test_dir="${1}"
    os="${2}"
    for step in "${test_dir}/steps"/*.sh "${test_dir}/os-specific/${os}/steps"/*.sh; do
        [[ -f "${step}" ]] && printf '%s\t%s\n' "$(basename "${step}")" "${step}"
    done | sort -s -t $'\t' -k1,1 | awk -F '\t' '
        { num = $1; sub(/-.*/, "", num) }
        (num in by_num) && by_num[num] != $1 { print "Two steps share number " num ": " by_num[num] " and " $1 > "/dev/stderr"; bad = 1 }
        { by_num[num] = $1; if (!($1 in path)) order[++n] = $1; path[$1] = $2 }
        END { if (bad) exit 1; for (i = 1; i <= n; i++) print path[order[i]] }'
}
