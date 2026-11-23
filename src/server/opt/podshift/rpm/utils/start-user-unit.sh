#!/usr/bin/env bash
# @file: start-user-unit.sh
# @source-dir: src/server/opt/podshift/rpm/utils
# @dest-dir: /opt/podshift/rpm/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Starts one user unit of the podshift user and reports the result.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5E61CFF3A863:-}" ]]; then
    DIR_5E61CFF3A863="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5E61CFF3A863
fi

# @description: Starts a user unit and reports the result.
# @arg: $1 - unit name
start-user-unit() {
    local unit state
    unit="${1}"
    # Output goes to /dev/null: under dnf (rpm_script_t) SELinux denies
    # systemd writing to any pipe or file the script creates, and the start
    # fails. The unit state is reported instead of the error text.
    # shellcheck source=../../fn/utils/print-step-warn.sh
    declare -F print-step-warn >/dev/null || source "${DIR_5E61CFF3A863}/../../fn/utils/print-step-warn.sh"
    if systemctl --machine="300@.host" --user start "${unit}" >/dev/null 2>&1; then
        echo -e "\tUser service '${unit}' start succeeded"
    else
        state="$(systemctl --machine="300@.host" --user is-active "${unit}" 2>/dev/null)"
        print-step-warn "User service '${unit}' start failed (state: ${state:-unknown})"
    fi
}
