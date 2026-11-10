#!/usr/bin/env bash
# @file: validate-test.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Checks that a test exists and may run on this platform.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that a test exists and may run on this platform.
# @arg: $1 - path of the test folder.
# @arg: $2 - the platform name, for example mac.
# @stderr: why the test cannot run here.
# @exitcode: 0 if it may run, 3 otherwise.
validate-test() {
    local test_dir os test_name platforms
    test_dir="${1}"
    os="${2}"
    test_name="$(basename "${test_dir}")"
    if [[ ! "${test_name}" =~ ^[a-z0-9-]+$ || ! -f "${test_dir}/main.sh" ]]; then
        echo "Unknown test: ${test_name:-<none>}" >&2
        return 3
    fi
    platforms="$(sed -n 's/^# @platforms: //p' "${test_dir}/main.sh")"
    if ! is-platform-allowed "${platforms}" "${os}"; then
        echo "${test_name} is not ready for ${os} (supported: ${platforms:-none})" >&2
        return 3
    fi
}
