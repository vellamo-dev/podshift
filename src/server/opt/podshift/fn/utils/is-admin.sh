#!/usr/bin/env bash
# @file: is-admin.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether the current user has administrator privileges.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the current user is root or has passwordless sudo.
# @exitcode: 0 if admin, 1 otherwise.
is-admin() {
    [[ "${EUID}" -eq 0 ]] || sudo -n true 2>/dev/null
}
