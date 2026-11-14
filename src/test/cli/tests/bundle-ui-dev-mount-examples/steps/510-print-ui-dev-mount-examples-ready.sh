#!/usr/bin/env bash
# @file: 510-print-ui-dev-mount-examples-ready.sh
# @source-dir: src/test/cli/tests/bundle-ui-dev-mount-examples/steps
# @group: test
# @category: step
# @description: Print Cockpit access with examples.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Cockpit URL again at the end, after the example resources were added.
# @arg: $1 - the run folder.
# @stdout: NOTE with the URL, and DETAIL lines for the examples and their cleanup.
# @exitcode: 0 if the VM has an IP address, 3 otherwise.
print-ui-dev-mount-examples-ready() {
    local run_dir ip
    run_dir="${1}"
    ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${TST_RPM_INSTALLER_VM} has no IP address yet"
        echo "Fix: ./test bundle-ui-dev-mount-examples"
        return 3
    fi
    write-log "${run_dir}" bundle-ui-dev-mount-examples "Cockpit URL with examples: https://${ip}:9090"
    echo "NOTE: https://${ip}:9090"
    echo "DETAIL: Open Cockpit at https://${ip}:9090; the example secrets, networks, images, volumes and containers are in place."
    echo "DETAIL: ./test cleanup-examples removes them again."
}
