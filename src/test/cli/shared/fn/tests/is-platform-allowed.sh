#!/usr/bin/env bash
# @file: is-platform-allowed.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Checks whether a test's @platforms value allows this platform.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks whether a test's @platforms value allows this platform.
# @details:
#   Versions are not checked yet.
# @arg: $1 - the @platforms value, for example "mac>=26 fedora>=45" or "all".
# @arg: $2 - the platform name, for example mac.
# @exitcode: 0 if allowed, 1 otherwise.
is-platform-allowed() {
    local platforms os platform
    platforms="${1}"
    os="${2}"
    for platform in ${platforms}; do
        [[ "${platform}" == "all" || "${platform}" == "${os}" || "${platform}" == "${os}>="* ]] && return 0
    done
    return 1
}
