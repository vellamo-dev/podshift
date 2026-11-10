#!/usr/bin/env bash
# @file: check-desktop-flag.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Stops the test lab on a Fedora computer that is not marked as a desktop.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the desktop flag file exists.
# @details:
#   This way the tests can never install the server package on the developer's own computer. The
#   flag path is PODSHIFT_DESKTOP_FLAG in the server main.conf.
# @arg: $1 - the repository root.
# @stderr: the problem and a Fix line when the flag is missing or its path is not found.
# @exitcode: 0 if the flag file exists, 1 otherwise.
check-desktop-flag() {
    local repo_root conf flag
    repo_root="${1}"
    conf="${repo_root}/src/server/opt/podshift/conf/main.conf"
    flag="$(sed -n 's/^export PODSHIFT_DESKTOP_FLAG="\(.*\)"$/\1/p' "${conf}" 2>/dev/null)"
    if [[ -z "${flag}" ]]; then
        echo "Desktop flag path not found in ${conf}" >&2
        echo "Fix: run the tests from a full PodShift checkout" >&2
        return 1
    fi
    [[ -e "${flag}" ]] && return 0
    echo "Desktop flag missing: ${flag}" >&2
    echo "Fix: sudo touch ${flag}" >&2
    return 1
}
