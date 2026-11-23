#!/usr/bin/env bash
# @file: cockpit-networks-list-display-path.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Shortens a path under HOME to ~/... for display.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Shortens a path under HOME to ~/... for display.
# @arg: $1 - path.
# @stdout: the display path.
# @exitcode: 0 always.
cockpit-networks-list-display-path() {
    local path
    path="${1-}"
    if [[ -n "${HOME:-}" && "${path}" == "${HOME}/"* ]]; then
        path="~/${path#"${HOME}/"}"
    fi
    printf '%s\n' "${path}"
}
