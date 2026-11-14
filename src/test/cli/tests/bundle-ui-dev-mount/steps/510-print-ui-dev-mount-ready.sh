#!/usr/bin/env bash
# @file: 510-print-ui-dev-mount-ready.sh
# @source-dir: src/test/cli/tests/bundle-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Print Cockpit access.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Cockpit URL and how to rebuild the plugin after the full setup.
# @arg: $1 - the run folder.
# @stdout: NOTE with the URL, and DETAIL lines for the rebuild command.
# @exitcode: 0 if the VM has an IP address, 3 otherwise.
print-ui-dev-mount-ready() {
    local run_dir ip mount_point
    run_dir="${1}"
    mount_point="${TST_DEV_SHARE_MOUNT:-/mnt/cockpit-podshift}"
    ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${TST_RPM_INSTALLER_VM} has no IP address yet"
        echo "Fix: ./test bundle-ui-dev-mount"
        return 3
    fi
    write-log "${run_dir}" bundle-ui-dev-mount "Cockpit URL: https://${ip}:9090"
    echo "NOTE: https://${ip}:9090"
    echo "DETAIL: Open Cockpit at https://${ip}:9090"
    if [[ -n "${TST_LIMA_CONFIG:-}" ]]; then
        echo "DETAIL: On a Mac, https://localhost:9090 also works (Lima forwards guest port 9090)."
    fi
    if [[ -n "${TST_DEV_SHARE}" && -d "${TST_DEV_SHARE}" ]]; then
        echo "DETAIL: The plugin is served from ${TST_DEV_SHARE} at ${mount_point}."
        echo "DETAIL: Rebuild it in cockpit-podshift with ./src/dev/run make watch, then refresh the browser."
    else
        echo "DETAIL: cockpit-podshift dist/ was not found, so the plugin share was not mounted."
        echo "DETAIL: Create that folder, then run ./test install-vm-start and this test again."
    fi
}
