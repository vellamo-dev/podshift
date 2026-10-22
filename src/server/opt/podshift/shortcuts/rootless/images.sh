#!/usr/bin/env bash
# @file: images.sh
# @dir: /opt/podshift/shortcuts/rootless
# @group: shortcuts
# @description: Lists all Podman images.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Lists all Podman images.
# @exitcode: 0 on success, 1 if not the podshift user.
rootless-images() {
    # shellcheck source=../../fn/utils/require-podshift.sh
    source /opt/podshift/fn/utils/require-podshift.sh --now || return 1
    # shellcheck source=../../fn/rootless/load-rootless-conf.sh
    source /opt/podshift/fn/rootless/load-rootless-conf.sh --now || return 1
    podman images
}

rootless-images
