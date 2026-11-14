#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/services-list
# @dest-dir: /opt/podshift/cockpit/api/modules/services-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Services list module: lists the podshift user's loaded systemd user services with their state.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7899F62CFB05:-}" ]]; then
    DIR_7899F62CFB05="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7899F62CFB05
fi

# shellcheck source=../../fn/services/cockpit-services-loaded.sh
declare -F cockpit-services-loaded >/dev/null || source "${DIR_7899F62CFB05}/../../fn/services/cockpit-services-loaded.sh"
# shellcheck source=../../fn/services/cockpit-services-items.sh
declare -F cockpit-services-items >/dev/null || source "${DIR_7899F62CFB05}/../../fn/services/cockpit-services-items.sh"

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code.
cockpit-services-list-systemctl() {
    systemctl --user "$@"
}

# @description: Lists the podshift user's loaded systemd user services as Services tab items.
# @details:
#   Runs systemctl --user list-units --type=service --all --plain --no-legend --no-pager and
#   keeps the loaded units (cockpit-services-loaded, the same list as the overview Services
#   count). With no units the output is {"items":[]} and nothing else runs. Otherwise one
#   systemctl --user show --timestamp=unix call reads Id, Description, LoadState, ActiveState,
#   SubState, StateChangeTimestamp, UnitFileState, UnitFilePreset, FragmentPath, SourcePath,
#   TriggeredBy, Result, MainPID and MemoryCurrent of all of them, and cockpit-services-items
#   builds the items. Everything is read-only. The process runs in the podshift session, so
#   systemctl --user talks to that user's manager, never the caller's.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 when systemctl or jq fails.
cockpit-module-services-list() {
    local raw show
    local -a units
    raw="$(cockpit-services-list-systemctl list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null)" || return 1
    mapfile -t units < <(cockpit-services-loaded "${raw}" | cut -f 1 | grep -E '^[A-Za-z0-9:_@\\]' | LC_ALL=C sort -u)
    if [[ "${#units[@]}" -eq 0 ]]; then
        printf '{"items":[]}\n'
        return 0
    fi
    show="$(cockpit-services-list-systemctl show --timestamp=unix \
        --property=Id,Description,LoadState,ActiveState,SubState,StateChangeTimestamp,UnitFileState,UnitFilePreset,FragmentPath,SourcePath,TriggeredBy,Result,MainPID,MemoryCurrent \
        -- "${units[@]}" 2>/dev/null)" || return 1
    printf '%s\n' "${show}" | cockpit-services-items
}
