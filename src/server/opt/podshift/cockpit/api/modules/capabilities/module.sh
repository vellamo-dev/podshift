#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/capabilities
# @dest-dir: /opt/podshift/cockpit/api/modules/capabilities
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Capabilities module: lists every recognised action with its metadata and contracts, failing closed on broken metadata.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_18D45E981154:-}" ]]; then
    DIR_18D45E981154="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_18D45E981154
fi

# @description: Lists every recognised action with its metadata and contracts.
# @details:
#   Walks the dispatch map in order and reuses the load and validate helpers. A retired action
#   is listed. Missing or invalid metadata fails with no partial output.
# @stdout: one JSON object with an actions array.
# @exitcode: 0 when the list was written, 1 when any entry could not be loaded or validated.
cockpit-module-capabilities() {
    local list entry action directory cap cap_rc collected
    # shellcheck source=../../fn/cockpit-dispatch-action.sh
    declare -F cockpit-dispatch-action >/dev/null || source "${DIR_18D45E981154}/../../fn/cockpit-dispatch-action.sh"
    # shellcheck source=../../fn/cockpit-load-capability.sh
    declare -F cockpit-load-capability >/dev/null || source "${DIR_18D45E981154}/../../fn/cockpit-load-capability.sh"
    # shellcheck source=../../fn/cockpit-validate-capability.sh
    declare -F cockpit-validate-capability >/dev/null || source "${DIR_18D45E981154}/../../fn/cockpit-validate-capability.sh"
    list="$(cockpit-dispatch-action list)" || return 1
    if ! printf '%s' "${list}" | jq -e 'type == "array" and length >= 1' >/dev/null 2>&1; then
        return 1
    fi
    collected="[]"
    while IFS= read -r entry; do
        [[ -n "${entry}" ]] || return 1
        action="$(printf '%s' "${entry}" | jq -r '.action')" || return 1
        directory="$(printf '%s' "${entry}" | jq -r '.directory')" || return 1
        cap="$(cockpit-load-capability "${directory}")" || return 1
        cockpit-validate-capability "${action}" "${cap}" && cap_rc=0 || cap_rc=$?
        [[ "${cap_rc}" -eq 0 || "${cap_rc}" -eq 2 ]] || return 1
        cap="$(printf '%s' "${cap}" | jq -c -s '.[0]')" || return 1
        collected="$(printf '%s' "${collected}" | jq -c --argjson item "${cap}" '. + [$item]')" || return 1
    done <<END_ENTRIES
$(printf '%s' "${list}" | jq -c '.[]')
END_ENTRIES
    jq -n -c --argjson actions "${collected}" '{actions:$actions}'
    return 0
}
