#!/usr/bin/env bash
# @file: cockpit-containers-list-systemctl.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs systemctl --user in the current (podshift) session.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments after --user.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code, or 1 when systemctl is missing.
cockpit-containers-list-systemctl() {
    systemctl --user "$@"
}
