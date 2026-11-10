#!/usr/bin/env bash
# @file: print-test-title.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Prints the human title of a test.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the human title of a test from the @title line in its main.sh.
# @arg: $1 - path of the test folder.
# @stdout: the title, for example Checking host, or the folder name if there is no @title.
print-test-title() {
    local test_dir title
    test_dir="${1}"
    title="$(sed -n 's/^# @title: //p' "${test_dir}/main.sh" | head -n 1)"
    printf '%s\n' "${title:-$(basename "${test_dir}")}"
}
