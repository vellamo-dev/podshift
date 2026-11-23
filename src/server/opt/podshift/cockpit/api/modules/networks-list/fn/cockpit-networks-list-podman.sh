#!/usr/bin/env bash
# @file: cockpit-networks-list-podman.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs podman in the current (podshift) session.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-networks-list-podman() {
    podman "$@"
}
