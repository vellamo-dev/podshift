#!/usr/bin/env bash
# @file: is-cloud-init-present.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Tells whether cloud-init is on the system.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 if cloud-init is on the system: its config file is there or the command is on PATH.
# @exitcode: 0 if cloud-init is present, 1 otherwise.
is-cloud-init-present() {
    [[ -f /etc/cloud/cloud.cfg ]] || command -v cloud-init >/dev/null 2>&1
}
