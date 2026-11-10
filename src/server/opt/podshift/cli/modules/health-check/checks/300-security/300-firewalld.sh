#!/usr/bin/env bash
# @file: 300-firewalld.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/300-security
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/300-security
# @host-edit: no
# @group: health-check
# @category: check
# @title: Firewalld
# @run-as: any
# @description: Verifies firewalld is running.
# @rationale: Without it, the host firewall is not enforcing the expected ports.
# @fix: sudo systemctl enable --now firewalld
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the firewalld check.
# @stdout: one TSV line: firewalld<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-firewalld() {
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        printf 'firewalld\tOK\trunning\n'
        return 0
    fi
    printf 'firewalld\tFAIL\tnot running\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-firewalld
