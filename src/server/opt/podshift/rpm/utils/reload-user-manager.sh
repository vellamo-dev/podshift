#!/usr/bin/env bash
# @file: reload-user-manager.sh
# @source-dir: src/server/opt/podshift/rpm/utils
# @dest-dir: /opt/podshift/rpm/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Reloads the systemd user manager of the podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_6E02D4A5C1E3:-}" ]]; then
    DIR_6E02D4A5C1E3="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_6E02D4A5C1E3
fi

# @description: Reloads the podshift user manager.
reload-user-manager() {
    # shellcheck source=../../fn/utils/print-step-warn.sh
    declare -F print-step-warn >/dev/null || source "${DIR_6E02D4A5C1E3}/../../fn/utils/print-step-warn.sh"
    if systemctl --machine="300@.host" --user daemon-reload >/dev/null 2>&1; then
        echo -e "\tUser manager 'user@300' reload succeeded"
    else
        print-step-warn "User manager 'user@300' reload failed"
    fi
}
