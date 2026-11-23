#!/usr/bin/env bash
# @file: cockpit-overview-status-label.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-status/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-status/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the display label for a unit, or nothing when the unit is missing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_56833974C8FF:-}" ]]; then
    DIR_56833974C8FF="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_56833974C8FF
fi

# @description: Prints the display label for a unit, or nothing when the unit is missing.
# @arg: $1 - systemctl show text.
# @stdout: the display label, or nothing.
# @exitcode: 0 always.
cockpit-overview-status-label() {
    local label
    # shellcheck source=../../../fn/overview/cockpit-overview-unit-state-from-show.sh
    declare -F cockpit-overview-unit-state-from-show >/dev/null || source "${DIR_56833974C8FF}/../../../fn/overview/cockpit-overview-unit-state-from-show.sh"
    if label="$(cockpit-overview-unit-state-from-show "${1-}")"; then
        printf '%s\n' "${label}"
    fi
}
