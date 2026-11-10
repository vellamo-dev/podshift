#!/usr/bin/env bash
# @file: drop-debounce.sh
# @source-dir: src/server/opt/podshift/fn/service
# @dest-dir: /opt/podshift/fn/service
# @host-edit: no
# @group: service
# @category: entry
# @description: Resets the drop debounce timer.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# shellcheck source=../../../../usr/lib/systemd/user/podshift-drop-debounce.service


# @description: Restarts the drop debounce timer, logging successes and failures.
# @exitcode: 0 always (non-fatal).
podshift-drop-debounce() {
    if systemctl --user restart podshift-drop.timer 2>/dev/null; then
        logger -t podshift-drop-debounce -p debug "debounce timer reset"
    else
        logger -t podshift-drop-debounce -p err "failed to reset the debounce timer"
    fi
    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-drop-debounce
