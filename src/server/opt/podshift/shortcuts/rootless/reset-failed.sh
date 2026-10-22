#!/usr/bin/env bash
# @file: reset-failed.sh
# @dir: /opt/podshift/shortcuts/rootless
# @group: shortcuts
# @description: Clears the failed state of the podshift user's systemd units.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Clears the failed state of the podshift user's systemd units.
# @exitcode: 0 on success, 1 if not the podshift user.
rootless-reset-failed() {
    # shellcheck source=../../fn/utils/require-podshift.sh
    source /opt/podshift/fn/utils/require-podshift.sh --now || return 1
    # shellcheck source=../../fn/rootless/load-rootless-conf.sh
    source /opt/podshift/fn/rootless/load-rootless-conf.sh --now || return 1
    systemctl --user reset-failed
}

rootless-reset-failed
