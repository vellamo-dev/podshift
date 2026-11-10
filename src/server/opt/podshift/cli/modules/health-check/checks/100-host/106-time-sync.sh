#!/usr/bin/env bash
# @file: 106-time-sync.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Time sync
# @run-as: any
# @description: Verifies the system clock is synchronised, asking chrony when chronyd runs.
# @rationale: A wrong clock breaks certificate validation and scheduling.
# @fix: sudo systemctl enable --now chronyd
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the time-sync check.
# @stdout: one TSV line: time-sync<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-time-sync() {
    if systemctl is-active --quiet chronyd 2>/dev/null && command -v chronyc >/dev/null; then
        if chronyc tracking 2>/dev/null | grep -q '^Leap status *: Normal'; then
            printf 'time-sync\tOK\tsynchronised (chronyd)\n'
            return 0
        fi
        printf 'time-sync\tWARN\tchronyd running, not synchronised\n'
        return 1
    fi
    if [[ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" == "yes" ]]; then
        printf 'time-sync\tOK\tsynchronised\n'
        return 0
    fi
    printf 'time-sync\tWARN\tnot synchronised, chronyd not running\n'
    return 1
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-time-sync
