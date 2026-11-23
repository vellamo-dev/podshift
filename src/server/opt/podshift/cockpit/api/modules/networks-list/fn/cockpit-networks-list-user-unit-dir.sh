#!/usr/bin/env bash
# @file: cockpit-networks-list-user-unit-dir.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the systemd user unit directory of the current (podshift) user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the systemd user unit directory of the current (podshift) user.
# @stdout: the directory path, or nothing when HOME is not set.
# @exitcode: 0 always.
cockpit-networks-list-user-unit-dir() {
    if [[ -n "${HOME:-}" ]]; then
        printf '%s\n' "${HOME}/.config/systemd/user"
    fi
}
