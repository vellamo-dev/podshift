#!/usr/bin/env bash
# @file: require-bash-version.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Stops the test run when Bash is older than the configured minimum.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the running shell and the bash on PATH against TST_BASH_MIN_VERSION.
# @details:
#   Both must be at least that major.minor. Prints a Fix line and returns 3 when they are not.
# @stderr: why Bash is too old, or that bash is missing on PATH, with the required minimum and the conf file that sets it.
# @exitcode: 0 if both are new enough, 3 otherwise (cannot run here).
require-bash-version() {
    local min conf running_version path path_version
    min="${TST_BASH_MIN_VERSION}"
    conf="src/test/cli/shared/conf/tests.conf"
    running_version="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
    if ! is-version-at-least "${running_version}" "${min}"; then
        echo "Bash ${running_version} (${BASH}) is too old to run the tests." >&2
        echo "Need at least Bash ${min} (set in ${conf})." >&2
        echo "Fix: install Bash ${min} or newer and run the tests with that bash first on PATH." >&2
        return 3
    fi
    path="$(command -v bash 2>/dev/null || true)"
    if [[ -z "${path}" ]]; then
        echo "No bash found on PATH. Child scripts use #!/usr/bin/env bash and bare bash." >&2
        echo "Need at least Bash ${min} (set in ${conf})." >&2
        echo "Fix: install Bash ${min} or newer and put it on PATH." >&2
        return 3
    fi
    path_version="$("${path}" -c 'printf %s.%s "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"')"
    if ! is-version-at-least "${path_version}" "${min}"; then
        echo "Bash on PATH is ${path_version} (${path}), too old to run the tests." >&2
        echo "Need at least Bash ${min} (set in ${conf})." >&2
        echo "Fix: install Bash ${min} or newer and put it first on PATH." >&2
        return 3
    fi
    return 0
}
