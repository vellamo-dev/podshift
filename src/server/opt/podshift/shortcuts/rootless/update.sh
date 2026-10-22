#!/usr/bin/env bash
# @file: update.sh
# @dir: /opt/podshift/shortcuts/rootless
# @group: shortcuts
# @description: Updates all containers with auto-update enabled.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Updates all containers with auto-update enabled.
# @exitcode: 0 on success, 1 if not the podshift user.
rootless-update() {
    # shellcheck source=../../fn/utils/require-podshift.sh
    source /opt/podshift/fn/utils/require-podshift.sh --now || return 1
    # shellcheck source=../../fn/rootless/load-rootless-conf.sh
    source /opt/podshift/fn/rootless/load-rootless-conf.sh --now || return 1
    podman auto-update
}

rootless-update
