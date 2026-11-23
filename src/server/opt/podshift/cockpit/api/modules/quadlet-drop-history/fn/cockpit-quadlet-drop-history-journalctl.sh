#!/usr/bin/env bash
# @file: cockpit-quadlet-drop-history-journalctl.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-drop-history/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-drop-history/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs journalctl as root, so the system journal with the user's entries is readable.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs journalctl as root, so the system journal with the user's entries is readable.
# @arg: $@ - journalctl arguments.
# @stdout: journalctl stdout.
# @exitcode: the journalctl exit code.
cockpit-quadlet-drop-history-journalctl() {
    journalctl "$@"
}
