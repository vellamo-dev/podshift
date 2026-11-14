#!/usr/bin/env bash
# @file: 540-print-ui-cockpit-url.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Print the Cockpit URL.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Cockpit URL where PodShift UI can be opened.
# @arg: $1 - the run folder.
# @stdout: NOTE with the URL or skipped, and DETAIL lines.
# @exitcode: 0 if the VM has an IP address or skipped, 3 otherwise.
print-ui-cockpit-url() {
    local run_dir ip
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${TST_RPM_INSTALLER_VM} has no IP address yet"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    write-log "${run_dir}" postinstall-ui-install "Cockpit URL: https://${ip}:9090"
    echo "NOTE: https://${ip}:9090"
    echo "DETAIL: Open Cockpit at https://${ip}:9090. PodShift UI is installed and stays installed."
    if [[ -n "${TST_LIMA_CONFIG:-}" ]]; then
        echo "DETAIL: On a Mac, https://localhost:9090 also works (Lima forwards guest port 9090)."
    fi
}
