#!/usr/bin/env bash
# @file: cockpit-overview-usage-podman.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage/fn
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
cockpit-overview-usage-podman() {
    podman "$@"
}
