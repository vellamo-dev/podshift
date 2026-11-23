#!/usr/bin/env bash
# @file: cockpit-overview-status-system-show.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-status/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-status/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints systemctl show text for one system unit.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints systemctl show text for one system unit.
# @arg: $1 - unit name, for example firewalld.service.
# @stdout: systemctl show properties, or nothing when the query fails.
# @exitcode: 0 always.
cockpit-overview-status-system-show() {
    systemctl show -p LoadState -p ActiveState -p SubState -- "${1}" 2>/dev/null || true
}
