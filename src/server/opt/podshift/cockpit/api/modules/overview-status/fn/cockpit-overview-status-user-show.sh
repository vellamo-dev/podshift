#!/usr/bin/env bash
# @file: cockpit-overview-status-user-show.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-status/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-status/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints systemctl show text for one of podshift's user units.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints systemctl show text for one of podshift's user units.
# @details:
#   Queries the podshift user manager at 300@.host, never the caller's session.
# @arg: $1 - unit name, for example podman.socket.
# @stdout: systemctl show properties, or nothing when the query fails.
# @exitcode: 0 always.
cockpit-overview-status-user-show() {
    systemctl --machine=300@.host --user show -p LoadState -p ActiveState -p SubState -- "${1}" 2>/dev/null || true
}
