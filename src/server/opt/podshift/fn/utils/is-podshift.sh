#!/usr/bin/env bash
# @file: is-podshift.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether the current user is the dedicated podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the current user is the podshift user (UID 300).
# @exitcode: 0 if podshift user, 1 otherwise.
is-podshift() {
    [[ "${EUID}" -eq 300 ]]
}
