#!/usr/bin/env bash
# @file: cockpit-services-list-systemctl.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/services-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/services-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs systemctl --user in the current (podshift) session.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code.
cockpit-services-list-systemctl() {
    systemctl --user "$@"
}
