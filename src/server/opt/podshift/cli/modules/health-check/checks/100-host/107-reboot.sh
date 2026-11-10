#!/usr/bin/env bash
# @file: 107-reboot.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Reboot
# @run-as: any
# @description: Verifies no reboot is pending.
# @rationale: A pending reboot means the running kernel is outdated.
# @fix: Reboot when convenient: sudo systemctl reboot
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the reboot check.
# @stdout: one TSV line: reboot<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-reboot() {
    if [[ ! -f /run/reboot-required ]]; then
        printf 'reboot\tOK\tnone pending\n'
        return 0
    fi
    printf 'reboot\tWARN\tpending\n'
    return 1
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-reboot
