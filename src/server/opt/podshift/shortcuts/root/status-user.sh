#!/usr/bin/env bash
# @file: status-user.sh
# @dir: /opt/podshift/shortcuts/root
# @group: shortcuts
# @description: Checks the status of the podshift user account service.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the status of the podshift user account service.
# @exitcode: 0 on success, 1 if not an administrator.
root-status-user() {
    # shellcheck source=../../fn/utils/require-admin.sh
    source /opt/podshift/fn/utils/require-admin.sh --now || return 1
    systemctl status user@300 --no-pager
}

root-status-user
