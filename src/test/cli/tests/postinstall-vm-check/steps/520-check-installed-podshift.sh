#!/usr/bin/env bash
# @file: 520-check-installed-podshift.sh
# @source-dir: src/test/cli/tests/postinstall-vm-check/steps
# @group: test
# @category: step
# @description: PodShift installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the podshift RPM is installed in the installer VM.
# @arg: $1 - the run folder.
# @stdout: NOTE with the installed version, or the problem and how to fix it.
# @exitcode: 0 if installed, 3 otherwise (cannot run here).
check-installed-podshift() {
    local run_dir version
    run_dir="${1}"
    if ! version="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q podshift 2>&1)"; then
        write-log "${run_dir}" postinstall-vm-check "rpm -q podshift: ${version}"
        echo "PodShift is not installed in ${TST_RPM_INSTALLER_VM}"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    write-log "${run_dir}" postinstall-vm-check "rpm -q podshift: ${version}"
    echo "NOTE: ${version}"
}
