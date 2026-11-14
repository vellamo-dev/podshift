#!/usr/bin/env bash
# @file: 510-verify-ui-package-version.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Verify installed cockpit-podshift version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that rpm -q cockpit-podshift works and gives the same name, version and release as the RPM file.
# @arg: $1 - the run folder.
# @stdout: NOTE with the package or skipped, or the problem.
# @exitcode: 0 if they match or skipped, 1 if the local RPM is gone, 2 otherwise.
verify-ui-package-version() {
    local run_dir file fmt installed from_file
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    file="$(find-ui-rpm 2>&1)" || { echo "${file}"; return 1; }
    fmt='%{name}-%{version}-%{release}.%{arch}'
    installed="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q --qf "${fmt}" cockpit-podshift 2>/dev/null)" || installed=""
    from_file="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -qp --qf "${fmt}" "${TST_RPM_INSTALLER_RPM_DIR}/${file##*/}" 2>/dev/null)" || from_file=""
    write-log "${run_dir}" postinstall-ui-install "Installed: ${installed:-none}"
    write-log "${run_dir}" postinstall-ui-install "RPM file: ${from_file:-unknown}"
    if [[ -z "${installed}" || "${installed}" != "${from_file}" ]]; then
        echo "Installed is ${installed:-none}, but the RPM file is ${from_file:-unknown}"
        return 2
    fi
    echo "NOTE: ${installed}"
}
