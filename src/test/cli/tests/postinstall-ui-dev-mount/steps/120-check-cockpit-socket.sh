#!/usr/bin/env bash
# @file: 120-check-cockpit-socket.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Check cockpit.socket.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that cockpit.socket is active in the installer VM, and starts it if it is not.
# @details:
#   The installer image already enables the socket. Starting it again is cheap and idempotent.
# @arg: $1 - the run folder.
# @stdout: NOTE with the socket state, or the problem if it did not start.
# @exitcode: 0 if cockpit.socket is active, 1 otherwise.
check-cockpit-socket() {
    local run_dir out state
    run_dir="${1}"
    state="$(vm-run "${TST_RPM_INSTALLER_VM}" systemctl is-active cockpit.socket 2>/dev/null || true)"
    if [[ "${state}" != "active" ]]; then
        if ! out="$(vm-run "${TST_RPM_INSTALLER_VM}" systemctl --no-pager start cockpit.socket 2>&1)"; then
            write-log "${run_dir}" postinstall-ui-dev-mount "systemctl start cockpit.socket: ${out}"
            echo "systemctl start cockpit.socket failed"
            printf '%s\n' "${out}" | sed 's/^/DETAIL: /'
            return 1
        fi
        state="$(vm-run "${TST_RPM_INSTALLER_VM}" systemctl is-active cockpit.socket 2>/dev/null || true)"
    fi
    write-log "${run_dir}" postinstall-ui-dev-mount "cockpit.socket: ${state:-unknown}"
    if [[ "${state}" != "active" ]]; then
        echo "cockpit.socket is not active (${state:-unknown})"
        return 1
    fi
    echo "NOTE: cockpit.socket ${state}"
}
