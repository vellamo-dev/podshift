#!/usr/bin/env bash
# @file: 530-print-ui-cockpit-url.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files/steps
# @group: test
# @category: step
# @description: Print the Cockpit URL.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Cockpit URL after the UI files were synced.
# @arg: $1 - the run folder.
# @stdout: NOTE with the URL or skipped, and DETAIL lines.
# @exitcode: 0 if the VM has an IP address or skipped, 3 otherwise.
print-ui-cockpit-url() {
    local run_dir dest ip
    run_dir="${1}"
    dest=/usr/share/cockpit/podshift
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        echo "NOTE: skipped"
        return 0
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${dest}" \
        || vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q /usr/local/share/cockpit/podshift; then
        echo "NOTE: skipped"
        return 0
    fi
    ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${TST_RPM_INSTALLER_VM} has no IP address yet"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    write-log "${run_dir}" postinstall-ui-sync-files "Cockpit URL: https://${ip}:9090"
    echo "NOTE: https://${ip}:9090"
    echo "DETAIL: Open Cockpit at https://${ip}:9090. The UI files in ${dest} were copied from the local dist."
    if [[ -n "${TST_LIMA_CONFIG:-}" ]]; then
        echo "DETAIL: On a Mac, https://localhost:9090 also works (Lima forwards guest port 9090)."
    fi
    echo "DETAIL: Reinstalling the UI RPM restores the packaged files."
}
