#!/usr/bin/env bash
# @file: 205-auto-update-timer.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/200-runtime
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/200-runtime
# @host-edit: no
# @group: health-check
# @category: check
# @title: Auto-update
# @run-as: podshift
# @description: Verifies the podman auto-update timer is active.
# @rationale: Without it, containers do not update automatically.
# @fix: As the podshift user: systemctl --user enable --now podman-auto-update.timer
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the auto-update-timer check.
# @stdout: one TSV line: auto-update-timer<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-auto-update-timer() {
    if systemctl --user is-active --quiet podman-auto-update.timer 2>/dev/null; then
        printf 'auto-update-timer\tOK\ttimer active\n'
        return 0
    fi
    printf 'auto-update-timer\tFAIL\tpodman-auto-update.timer inactive\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-auto-update-timer
