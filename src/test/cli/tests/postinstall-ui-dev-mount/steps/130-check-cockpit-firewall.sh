#!/usr/bin/env bash
# @file: 130-check-cockpit-firewall.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Check the Cockpit firewall.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the firewalld cockpit service is already allowed, when firewalld is running.
# @details:
#   If firewalld is not running, the step is skipped. It does not change firewall rules.
# @arg: $1 - the run folder.
# @stdout: NOTE with the result, or the problem if the service is not allowed.
# @exitcode: 0 if the service is allowed or firewalld is not running, 3 if the service is not allowed.
check-cockpit-firewall() {
    local run_dir state
    run_dir="${1}"
    state="$(vm-run "${TST_RPM_INSTALLER_VM}" systemctl is-active firewalld 2>/dev/null || true)"
    if [[ "${state}" != "active" ]]; then
        write-log "${run_dir}" postinstall-ui-dev-mount "firewalld: ${state:-not running}, skip cockpit service"
        echo "NOTE: firewalld not running, skipped"
        return 0
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" firewall-cmd --query-service=cockpit >/dev/null 2>&1; then
        write-log "${run_dir}" postinstall-ui-dev-mount "firewall-cmd: cockpit service allowed"
        echo "NOTE: cockpit service allowed"
        return 0
    fi
    write-log "${run_dir}" postinstall-ui-dev-mount "firewall-cmd: cockpit service not allowed"
    echo "The firewalld cockpit service is not allowed"
    echo "Fix: ./test install-image"
    return 3
}
