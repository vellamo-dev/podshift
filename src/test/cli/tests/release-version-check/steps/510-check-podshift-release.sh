#!/usr/bin/env bash
# @file: 510-check-podshift-release.sh
# @source-dir: src/test/cli/tests/release-version-check/steps
# @group: test
# @category: step
# @description: Check podshift release.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Compares the podshift version on GitHub with Copr, or skips when TST_RELEASE_PACKAGES leaves it out.
# @arg: $1 - the run folder.
# @stdout: NOTE with both versions, DETAIL lines with the sources, and the reason first when it fails.
# @exitcode: 0 when they match or skipped, 1 on a network error, 2 when Copr is behind or ahead.
check-podshift-release() {
    local run_dir
    run_dir="${1}"
    if [[ " ${TST_RELEASE_PACKAGES} " != *" podshift "* ]]; then
        echo "NOTE: skipped"
        return 0
    fi
    check-release-version podshift "${TST_RELEASE_CHROOT}" "${run_dir}"
}
