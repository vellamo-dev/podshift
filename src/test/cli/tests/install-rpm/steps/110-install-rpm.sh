#!/usr/bin/env bash
# @file: 110-install-rpm.sh
# @source-dir: src/test/cli/tests/install-rpm/steps
# @group: test
# @category: step
# @description: Install RPM package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Installs the copied RPM in the VM with dnf.
# @details:
#   The full dnf output goes to install.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file name, or the last lines of install.log on failure.
# @exitcode: 0 if installed, 1 if the RPM is not found, 2 if dnf failed.
install-rpm() {
    local run_dir file log_file
    run_dir="${1}"
    log_file="${run_dir}/install.log"
    file="$(find-exported-rpm "${TST_RPM_SHARE_DIR}" 2>&1)" || { echo "${file}"; return 1; }
    if ! vm-run "${TST_RPM_INSTALLER_VM}" dnf install -y "${TST_RPM_INSTALLER_RPM_DIR}/${file##*/}" >"${log_file}" 2>&1; then
        write-log "${run_dir}" install-rpm "dnf install ${file##*/}: failed, see install.log"
        echo "dnf install failed. Last lines of install.log:"
        tail -n 15 "${log_file}"
        return 2
    fi
    write-log "${run_dir}" install-rpm "dnf install ${file##*/}: done, see install.log"
    echo "NOTE: ${file##*/}"
}
