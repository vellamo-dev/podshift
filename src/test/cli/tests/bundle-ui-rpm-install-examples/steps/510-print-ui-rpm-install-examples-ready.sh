#!/usr/bin/env bash
# @file: 510-print-ui-rpm-install-examples-ready.sh
# @source-dir: src/test/cli/tests/bundle-ui-rpm-install-examples/steps
# @group: test
# @category: step
# @description: Print Cockpit access with examples.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Cockpit URL at the end, whether PodShift UI was installed, and that the examples are in place.
# @arg: $1 - the run folder.
# @stdout: NOTE with the URL, and DETAIL lines about PodShift UI and the examples.
# @exitcode: 0 if the VM has an IP address, 3 otherwise.
print-ui-rpm-install-examples-ready() {
    local run_dir ip
    run_dir="${1}"
    ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${TST_RPM_INSTALLER_VM} has no IP address yet"
        echo "Fix: ./test bundle-ui-rpm-install-examples"
        return 3
    fi
    write-log "${run_dir}" bundle-ui-rpm-install-examples "Cockpit URL with examples: https://${ip}:9090"
    echo "NOTE: https://${ip}:9090"
    echo "DETAIL: Open Cockpit at https://${ip}:9090"
    if [[ -n "${TST_LIMA_CONFIG:-}" ]]; then
        echo "DETAIL: On a Mac, https://localhost:9090 also works (Lima forwards guest port 9090)."
    fi
    if [[ "${TST_UI_PRESENT}" == "true" ]]; then
        write-log "${run_dir}" bundle-ui-rpm-install-examples "PodShift UI: installed from ${TST_UI_RPM_SHARE_DIR}"
        echo "DETAIL: PodShift UI is installed from the cockpit-podshift RPM in ${TST_UI_RPM_SHARE_DIR}."
    else
        write-log "${run_dir}" bundle-ui-rpm-install-examples "PodShift UI: cockpit-podshift not found, skipped"
        echo "DETAIL: cockpit-podshift was not found at ${TST_UI_SOURCE}, so PodShift UI was not built or installed."
    fi
    echo "DETAIL: The example secrets, networks, images, volumes and containers are in place."
    echo "DETAIL: ./test cleanup-examples removes them again."
}
