#!/usr/bin/env bash
# @file: 500-networkmanager.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/500-network
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/500-network
# @host-edit: no
# @group: health-check
# @category: check
# @title: NetworkManager
# @run-as: any
# @description: Verifies NetworkManager is active.
# @rationale: Without it, network devices are not managed.
# @fix: sudo systemctl enable --now NetworkManager
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the networkmanager check.
# @stdout: one TSV line: networkmanager<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-networkmanager() {
    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        printf 'networkmanager\tOK\tactive\n'
        return 0
    fi
    printf 'networkmanager\tFAIL\tinactive\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-networkmanager
