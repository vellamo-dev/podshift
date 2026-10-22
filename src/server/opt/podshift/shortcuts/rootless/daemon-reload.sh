#!/usr/bin/env bash
# @file: daemon-reload.sh
# @dir: /opt/podshift/shortcuts/rootless
# @group: shortcuts
# @description: Reloads the podshift user's systemd manager configuration.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reloads the podshift user's systemd manager configuration.
# @exitcode: 0 on success, 1 if not the podshift user.
rootless-daemon-reload() {
    # shellcheck source=../../fn/utils/require-podshift.sh
    source /opt/podshift/fn/utils/require-podshift.sh --now || return 1
    # shellcheck source=../../fn/rootless/load-rootless-conf.sh
    source /opt/podshift/fn/rootless/load-rootless-conf.sh --now || return 1
    systemctl --user daemon-reload
}

rootless-daemon-reload
