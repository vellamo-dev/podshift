#!/usr/bin/env bash
# @file: networks.sh
# @source-dir: src/server/opt/podshift/shortcuts/rootless
# @dest-dir: /opt/podshift/shortcuts/rootless
# @host-edit: no
# @group: shortcuts
# @category: shortcut
# @description: Lists all Podman networks.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Lists all Podman networks.
# @exitcode: 0 on success, 1 if not the podshift user.
rootless-networks() {
    # shellcheck source=../../fn/utils/require-podshift.sh
    declare -F require-podshift >/dev/null || source /opt/podshift/fn/utils/require-podshift.sh
    require-podshift || return 1
    # shellcheck source=../../fn/rootless/load-rootless-conf.sh
    declare -F load-rootless-conf >/dev/null || source /opt/podshift/fn/rootless/load-rootless-conf.sh || return 1
    load-rootless-conf || return 1
    podman network ls
}

rootless-networks
