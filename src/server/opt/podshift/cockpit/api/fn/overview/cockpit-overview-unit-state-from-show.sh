#!/usr/bin/env bash
# @file: cockpit-overview-unit-state-from-show.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Maps systemctl show output for one unit to a final overview status label.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_847FDF72A228:-}" ]]; then
    DIR_847FDF72A228="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_847FDF72A228
fi

# @description: Prints the display label for a unit from systemctl show output.
# @details:
#   Reads LoadState, ActiveState and SubState from the text. A missing unit
#   (LoadState not-found) or empty text fails so the caller can store null.
# @arg: $1 - optional systemctl show text; when omitted, the text is read from stdin.
# @stdout: one label, such as Running or Stopped.
# @exitcode: 0 when a label was printed, 1 when the unit is missing or the state is unknown.
cockpit-overview-unit-state-from-show() {
    local raw load active sub
    raw="${1-}"
    if [[ -z "${raw}" ]]; then
        raw="$(cat)"
    fi
    [[ -n "${raw}" ]] || return 1
    load="$(printf '%s\n' "${raw}" | awk -F= '$1=="LoadState" { print $2; exit }')"
    active="$(printf '%s\n' "${raw}" | awk -F= '$1=="ActiveState" { print $2; exit }')"
    sub="$(printf '%s\n' "${raw}" | awk -F= '$1=="SubState" { print $2; exit }')"
    case "${load}" in
        not-found|'')
            return 1
            ;;
    esac
    # shellcheck source=./cockpit-overview-unit-state.sh
    declare -F cockpit-overview-unit-state >/dev/null || source "${DIR_847FDF72A228}/cockpit-overview-unit-state.sh"
    cockpit-overview-unit-state "${active}" "${sub}"
}
