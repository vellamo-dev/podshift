#!/usr/bin/env bash
# @file: cockpit-overview-info-install-type.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the install type, desktop or server.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A2657F4AB9DB:-}" ]]; then
    DIR_A2657F4AB9DB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A2657F4AB9DB
fi

# @description: Prints the install type, desktop or server.
# @details:
#   Runs the check in a subshell, so the main configuration it loads stays out of this module.
# @stdout: desktop or server.
# @exitcode: 0 always.
cockpit-overview-info-install-type() {
    # shellcheck source=../../../../../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${DIR_A2657F4AB9DB}/../../../../../fn/utils/is-install-type-desktop.sh"
    if (is-install-type-desktop); then
        printf 'desktop\n'
    else
        printf 'server\n'
    fi
}
