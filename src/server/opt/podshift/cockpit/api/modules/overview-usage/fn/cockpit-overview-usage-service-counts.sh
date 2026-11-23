#!/usr/bin/env bash
# @file: cockpit-overview-usage-service-counts.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Counts the podshift user's loaded systemd user service units as active over total.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_576260D5BFEC:-}" ]]; then
    DIR_576260D5BFEC="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_576260D5BFEC
fi

# @description: Counts the podshift user's loaded systemd user service units as active over total.
# @details:
#   Runs systemctl --user list-units --type=service --all --plain --no-legend --no-pager
#   through cockpit-overview-usage-systemctl, then formats the list with
#   cockpit-overview-service-counts. Nothing is printed when systemctl fails.
# @stdout: a value such as 2 / 10 or 0, or nothing when the list cannot be read.
# @exitcode: 0 always.
cockpit-overview-usage-service-counts() {
    local raw
    # shellcheck source=./cockpit-overview-usage-systemctl.sh
    declare -F cockpit-overview-usage-systemctl >/dev/null || source "${DIR_576260D5BFEC}/cockpit-overview-usage-systemctl.sh"
    # shellcheck source=../../../fn/overview/cockpit-overview-service-counts.sh
    declare -F cockpit-overview-service-counts >/dev/null || source "${DIR_576260D5BFEC}/../../../fn/overview/cockpit-overview-service-counts.sh"
    if raw="$(cockpit-overview-usage-systemctl list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null)"; then
        printf '%s\n' "${raw}" | cockpit-overview-service-counts
    fi
}
