#!/usr/bin/env bash
# @file: 140-remove-old-ui-package.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Remove installed cockpit-podshift.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Logs whether cockpit-podshift is already installed in the VM, and removes it if so.
# @details:
#   This way every run installs into a clean state. The dnf output goes to ui-remove.log.
# @arg: $1 - the run folder.
# @stdout: NOTE not installed, removed or skipped, or the problem.
# @exitcode: 0 if not installed anymore or skipped, 1 otherwise.
remove-old-ui-package() {
    local run_dir version
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    if ! version="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q cockpit-podshift 2>/dev/null)"; then
        write-log "${run_dir}" postinstall-ui-install "cockpit-podshift: not installed before"
        echo "NOTE: not installed"
        return 0
    fi
    write-log "${run_dir}" postinstall-ui-install "cockpit-podshift: already installed (${version}), removing"
    if ! vm-run "${TST_RPM_INSTALLER_VM}" dnf remove -y cockpit-podshift >"${run_dir}/ui-remove.log" 2>&1; then
        write-log "${run_dir}" postinstall-ui-install "dnf remove cockpit-podshift: failed, see ui-remove.log"
        echo "dnf remove cockpit-podshift failed. Last lines of ui-remove.log:"
        tail -n 15 "${run_dir}/ui-remove.log"
        return 1
    fi
    write-log "${run_dir}" postinstall-ui-install "dnf remove cockpit-podshift: done, see ui-remove.log"
    echo "NOTE: removed ${version}"
}
