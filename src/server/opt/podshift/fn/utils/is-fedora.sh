#!/usr/bin/env bash
# @file: is-fedora.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether the running system is Fedora.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the running system is Fedora.
# @exitcode: 0 if Fedora, 1 otherwise.
is-fedora() {
    local os_id
    [[ -r /etc/os-release ]] || return 1
    os_id="$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    [[ "${os_id}" == "fedora" ]]
}
