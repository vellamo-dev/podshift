#!/usr/bin/env bash
# @file: 503-pcp.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/500-network
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/500-network
# @host-edit: no
# @group: health-check
# @category: check
# @title: PCP metrics
# @run-as: any
# @description: Verifies the PCP metrics daemon is active.
# @rationale: Without it, performance metrics are not collected.
# @fix: sudo systemctl enable --now pmcd pmlogger
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the pcp check.
# @stdout: one TSV line: pcp<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-pcp() {
    if systemctl is-active --quiet pmcd 2>/dev/null \
        || systemctl is-active --quiet pmlogger 2>/dev/null; then
        printf 'pcp\tOK\tactive\n'
        return 0
    fi
    printf 'pcp\tWARN\tinactive\n'
    return 1
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-pcp
