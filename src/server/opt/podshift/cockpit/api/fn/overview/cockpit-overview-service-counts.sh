#!/usr/bin/env bash
# @file: cockpit-overview-service-counts.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Counts loaded systemd user service units from systemctl list-units text as active over total.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E8C1A04B7D26:-}" ]]; then
    DIR_E8C1A04B7D26="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E8C1A04B7D26
fi

# shellcheck source=cockpit-overview-count.sh
declare -F cockpit-overview-count >/dev/null || source "${DIR_E8C1A04B7D26}/cockpit-overview-count.sh"
# shellcheck source=../services/cockpit-services-loaded.sh
declare -F cockpit-services-loaded >/dev/null || source "${DIR_E8C1A04B7D26}/../services/cockpit-services-loaded.sh"

# @description: Counts loaded systemd user service units from systemctl list-units text as active over total.
# @details:
#   Reads list-units output from stdin, or from $1 when that argument is given. The units come
#   from cockpit-services-loaded, the same list the services-list action shows: only units
#   whose load state is loaded are counted. Units marked not-found, masked or error are
#   omitted. The active count is the number of those units whose ACTIVE state is active,
#   including running and exited. A leading failed-unit marker is ignored. A total of 0
#   is printed as 0.
# @arg: $1 - optional systemctl list-units text; when omitted, the text is read from stdin.
# @stdout: a value such as 2 / 10, or 0 when no loaded units are listed.
# @exitcode: 0 always.
cockpit-overview-service-counts() {
    local raw used all
    raw="${1-}"
    if [[ "$#" -eq 0 ]]; then
        raw="$(cat)"
    fi
    read -r used all < <(cockpit-services-loaded "${raw}" | awk -F '\t' '
        { all++; if ($2 == "active") used++ }
        END { print used + 0, all + 0 }
    ')
    cockpit-overview-count "${used}" "${all}"
}
