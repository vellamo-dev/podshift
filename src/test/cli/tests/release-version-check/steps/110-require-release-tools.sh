#!/usr/bin/env bash
# @file: 110-require-release-tools.sh
# @source-dir: src/test/cli/tests/release-version-check/steps
# @group: test
# @category: step
# @description: Check curl, jq and the package list.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops this test when curl or jq is missing, or TST_RELEASE_PACKAGES has an unknown package.
# @arg: $1 - the run folder.
# @stdout: NOTE with the packages and the chroot, or the problem with a Fix line.
# @exitcode: 0 when ready, 1 for an unknown package, 3 when curl or jq is missing.
require-release-tools() {
    local run_dir tool package
    run_dir="${1}"
    for tool in curl jq; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            echo "${tool} was not found"
            echo "Fix: install ${tool}"
            return 3
        fi
    done
    [[ -n "${TST_RELEASE_PACKAGES// /}" ]] || { echo "TST_RELEASE_PACKAGES is empty"; echo "Fix: use podshift, cockpit-podshift or both"; return 1; }
    for package in ${TST_RELEASE_PACKAGES}; do
        case "${package}" in
            podshift | cockpit-podshift) ;;
            *)
                echo "Unknown package in TST_RELEASE_PACKAGES: ${package}"
                echo "Fix: use podshift, cockpit-podshift or both"
                return 1
                ;;
        esac
    done
    write-log "${run_dir}" release-version-check "Packages: ${TST_RELEASE_PACKAGES}, chroot ${TST_RELEASE_CHROOT}, branch ${TST_RELEASE_BRANCH}"
    echo "NOTE: ${TST_RELEASE_PACKAGES}, ${TST_RELEASE_CHROOT}"
}
