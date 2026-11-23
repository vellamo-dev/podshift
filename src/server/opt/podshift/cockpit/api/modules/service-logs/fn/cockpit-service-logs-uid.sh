#!/usr/bin/env bash
# @file: cockpit-service-logs-uid.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/service-logs/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/service-logs/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the UID of the podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the UID of the podshift user.
# @stdout: the UID, from id -u podshift.
# @exitcode: the id exit code.
cockpit-service-logs-uid() {
    id -u podshift 2>/dev/null
}
