#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/ping
# @dest-dir: /opt/podshift/cockpit/api/modules/ping
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Ping module: confirms the handler can run a module in the podshift session and returns pong and the inner uid.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns pong and the process's effective uid, not a fixed number.
# @stdout: a JSON object with pong true and uid set to the effective uid.
# @exitcode: 0 always.
cockpit-module-ping() {
    local uid
    uid="${EUID}"
    printf '{"pong":true,"uid":%s}\n' "${uid}"
    return 0
}
