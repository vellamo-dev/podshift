#!/usr/bin/env bash
# @file: 301-fail2ban.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/300-security
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/300-security
# @host-edit: no
# @group: health-check
# @category: check
# @title: Fail2ban
# @run-as: any
# @install-type: server
# @description: Verifies fail2ban is running.
# @rationale: Without it, brute-force attempts are not blocked.
# @fix: sudo systemctl enable --now fail2ban
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the fail2ban check.
# @stdout: one TSV line: fail2ban<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-fail2ban() {
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        printf 'fail2ban\tOK\trunning\n'
        return 0
    fi
    printf 'fail2ban\tFAIL\tnot running\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-fail2ban
