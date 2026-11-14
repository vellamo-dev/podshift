#!/usr/bin/env bash
# @file: 110-check-ui-install-ready.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Check VM, PodShift and cockpit-podshift RPM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the VM is running, PodShift is installed there, and a local cockpit-podshift RPM exists.
# @details:
#   When the cockpit-podshift project is missing, this and every later step pass with a skipped note.
# @arg: $1 - the run folder.
# @stdout: NOTE with the RPM name or skipped, or the problem and how to fix it.
# @exitcode: 0 if ready or skipped, 3 otherwise (cannot run here).
check-ui-install-ready() {
    local run_dir version file
    run_dir="${1}"
    if [[ "${TST_UI_PRESENT}" != "true" ]]; then
        write-log "${run_dir}" postinstall-ui-install "cockpit-podshift: not found at ${TST_UI_SOURCE}, skipped"
        echo "NOTE: cockpit-podshift not found, skipped"
        return 0
    fi
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        write-log "${run_dir}" postinstall-ui-install "VM ${TST_RPM_INSTALLER_VM}: not running"
        echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    if ! version="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q podshift 2>&1)"; then
        write-log "${run_dir}" postinstall-ui-install "rpm -q podshift: ${version}"
        echo "PodShift is not installed in ${TST_RPM_INSTALLER_VM}"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    write-log "${run_dir}" postinstall-ui-install "rpm -q podshift: ${version}"
    if ! file="$(find-ui-rpm 2>&1)"; then
        write-log "${run_dir}" postinstall-ui-install "${file}"
        echo "${file}"
        echo "Fix: ./test ui-rpm-build"
        return 3
    fi
    write-log "${run_dir}" postinstall-ui-install "Local RPM: ${file}"
    echo "NOTE: ${file##*/}"
}
