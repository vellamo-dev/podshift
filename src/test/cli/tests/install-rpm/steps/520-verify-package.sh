#!/usr/bin/env bash
# @file: 520-verify-package.sh
# @source-dir: src/test/cli/tests/install-rpm/steps
# @group: test
# @category: step
# @description: Verify package installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that rpm sees the podshift package as installed.
# @arg: $1 - the run folder.
# @stdout: NOTE with the installed version.
# @exitcode: 0 if installed, 2 otherwise.
verify-package() {
    local run_dir version
    run_dir="${1}"
    if ! version="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q podshift 2>&1)"; then
        write-log "${run_dir}" install-rpm "Check package installed: failed"
        echo "${version}"
        return 2
    fi
    write-log "${run_dir}" install-rpm "Check package installed: ${version}"
    echo "NOTE: ${version}"
}
