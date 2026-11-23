#!/usr/bin/env bash
# @file: is-wheel-member.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether the current user is a member of the wheel group.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the current user is in the wheel group, the Fedora sudo group.
# @details:
#   Reads the group names with id -Gn and never asks sudo, so nothing is logged and no prompt can
#   appear. It says who may administer, not whether sudo works now: commands use is-admin for that.
# @exitcode: 0 if a member of wheel, 1 otherwise.
is-wheel-member() {
    [[ " $(id -Gn 2>/dev/null) " == *" wheel "* ]]
}
