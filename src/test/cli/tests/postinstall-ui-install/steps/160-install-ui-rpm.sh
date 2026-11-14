#!/usr/bin/env bash
# @file: 160-install-ui-rpm.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Install cockpit-podshift RPM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Installs the copied cockpit-podshift RPM in the VM with dnf install -y.
# @details:
#   The full dnf output goes to ui-install.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: the last dnf lines if it failed, or NOTE skipped.
# @exitcode: 0 if installed or skipped, 1 if the local RPM is gone, 2 if dnf failed.
install-ui-rpm() {
    local run_dir file vm_file
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    file="$(find-ui-rpm 2>&1)" || { echo "${file}"; return 1; }
    vm_file="${TST_RPM_INSTALLER_RPM_DIR}/${file##*/}"
    if ! vm-run "${TST_RPM_INSTALLER_VM}" dnf install -y "${vm_file}" >"${run_dir}/ui-install.log" 2>&1; then
        write-log "${run_dir}" postinstall-ui-install "dnf install ${vm_file}: failed, see ui-install.log"
        echo "dnf install failed. Last lines of ui-install.log:"
        tail -n 15 "${run_dir}/ui-install.log"
        return 2
    fi
    write-log "${run_dir}" postinstall-ui-install "dnf install ${vm_file}: done, see ui-install.log"
}
