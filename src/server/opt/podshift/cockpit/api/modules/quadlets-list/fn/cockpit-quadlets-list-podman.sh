#!/usr/bin/env bash
# @file: cockpit-quadlets-list-podman.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlets-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlets-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs podman, replaced in tests so the listing can be stubbed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podman, replaced in tests so the listing can be stubbed.
# @arg: $@ - podman arguments (quadlet ls --format json).
# @stdout: the JSON listing from podman.
# @exitcode: podman's exit code.
cockpit-quadlets-list-podman() {
    podman "$@"
}
