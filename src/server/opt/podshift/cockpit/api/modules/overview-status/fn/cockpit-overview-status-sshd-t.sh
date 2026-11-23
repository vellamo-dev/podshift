#!/usr/bin/env bash
# @file: cockpit-overview-status-sshd-t.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-status/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-status/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the effective sshd configuration from sshd -T.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the effective sshd configuration from sshd -T.
# @stdout: sshd -T text, or nothing when the command fails.
# @exitcode: 0 always.
cockpit-overview-status-sshd-t() {
    sshd -T 2>/dev/null || true
}
