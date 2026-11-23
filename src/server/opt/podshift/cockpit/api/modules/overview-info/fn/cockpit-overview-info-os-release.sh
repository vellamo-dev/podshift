#!/usr/bin/env bash
# @file: cockpit-overview-info-os-release.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the contents of /etc/os-release, if it can be read.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the contents of /etc/os-release, if it can be read.
# @stdout: os-release text, or nothing.
# @exitcode: 0 always.
cockpit-overview-info-os-release() {
    cat /etc/os-release 2>/dev/null || true
}
