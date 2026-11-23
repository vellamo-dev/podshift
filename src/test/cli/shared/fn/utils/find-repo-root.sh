#!/usr/bin/env bash
# @file: find-repo-root.sh
# @source-dir: src/test/cli/shared/fn/utils
# @group: test
# @category: helper
# @description: Finds the repository root, the folder that holds podshift.spec.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the nearest folder at or above the given one that holds podshift.spec.
# @details:
#   Test files load this helper by a path relative to their own folder: every suite keeps its
#   tests in src/test/cli/tests/<suite>/scripts/, so the helper is always ../../../shared/fn/utils
#   from there. The caller passes its own absolute folder, so the result does not depend on the cwd.
# @arg: $1 - absolute folder to start from, normally the test file's folder.
# @stdout: the repository root.
# @stderr: a note when no podshift.spec is found.
# @exitcode: 0 if the root was found, 1 otherwise.
find-repo-root() {
    local dir
    dir="${1}"
    while [[ -n "${dir}" && "${dir}" != "/" && ! -f "${dir}/podshift.spec" ]]; do
        dir="$(dirname -- "${dir}")"
    done
    if [[ -z "${dir}" || ! -f "${dir}/podshift.spec" ]]; then
        echo "find-repo-root: no podshift.spec at or above ${1}" >&2
        return 1
    fi
    echo "${dir}"
}
