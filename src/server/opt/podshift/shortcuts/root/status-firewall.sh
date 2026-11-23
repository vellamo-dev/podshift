#!/usr/bin/env bash
# @file: status-firewall.sh
# @source-dir: src/server/opt/podshift/shortcuts/root
# @dest-dir: /opt/podshift/shortcuts/root
# @host-edit: no
# @group: shortcuts
# @category: shortcut
# @description: Checks the status of the system firewall service.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the status of the system firewall service.
# @arg: $@ - none; any argument is refused.
# @exitcode: 0 on success, 1 if given an argument or not an administrator.
root-status-firewall() {
    # shellcheck source=../../fn/utils/require-no-args.sh
    declare -F require-no-args >/dev/null || source /opt/podshift/fn/utils/require-no-args.sh
    require-no-args status-firewall "$@" || return 1
    # shellcheck source=../../fn/utils/require-admin.sh
    declare -F require-admin >/dev/null || source /opt/podshift/fn/utils/require-admin.sh
    require-admin || return 1
    systemctl status firewalld --no-pager
}

root-status-firewall "$@"
