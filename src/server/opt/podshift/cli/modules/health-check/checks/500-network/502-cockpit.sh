#!/usr/bin/env bash
# @file: 502-cockpit.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/500-network
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/500-network
# @host-edit: no
# @group: health-check
# @category: check
# @title: Cockpit
# @run-as: any
# @description: Verifies the cockpit socket is active.
# @rationale: Without it, the web admin UI is unavailable.
# @fix: sudo systemctl enable --now cockpit.socket
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the cockpit check.
# @stdout: one TSV line: cockpit<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-cockpit() {
    if systemctl is-active --quiet cockpit.socket 2>/dev/null; then
        printf 'cockpit\tOK\tsocket active\n'
        return 0
    fi
    printf 'cockpit\tWARN\tcockpit.socket inactive\n'
    return 1
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-cockpit
