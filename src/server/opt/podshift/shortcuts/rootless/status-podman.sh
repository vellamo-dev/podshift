#!/usr/bin/env bash
# @file: status-podman.sh
# @dir: /opt/podshift/shortcuts/rootless
# @group: shortcuts
# @description: Checks the status of the rootless Podman API service.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the status of the rootless Podman API service.
# @exitcode: 0 on success, 1 if not the podshift user.
rootless-status-podman() {
    # shellcheck source=../../fn/utils/require-podshift.sh
    source /opt/podshift/fn/utils/require-podshift.sh --now || return 1
    # shellcheck source=../../fn/rootless/load-rootless-conf.sh
    source /opt/podshift/fn/rootless/load-rootless-conf.sh --now || return 1
    systemctl --user status podman.socket --no-pager
}

rootless-status-podman
