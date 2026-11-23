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
#   Walks the dispatch map in order (all-fields mode, no jq) and reuses the load and validate helpers.
#   A retired action is listed. Missing or invalid metadata fails with no partial output. The
#   validated documents, one JSON value each, are joined into the actions array with one jq call.
# @stdout: one JSON object with an actions array.
# @exitcode: 0 when the list was written, 1 when any entry could not be loaded or validated.
cockpit-module-capabilities() {
    local fields line action directory cap cap_rc collected count
    # shellcheck source=../../fn/cockpit-dispatch-action.sh
    declare -F cockpit-dispatch-action >/dev/null || source "${DIR_18D45E981154}/../../fn/cockpit-dispatch-action.sh"
    # shellcheck source=../../fn/cockpit-load-capability.sh
    declare -F cockpit-load-capability >/dev/null || source "${DIR_18D45E981154}/../../fn/cockpit-load-capability.sh"
    # shellcheck source=../../fn/cockpit-validate-capability.sh
    declare -F cockpit-validate-capability >/dev/null || source "${DIR_18D45E981154}/../../fn/cockpit-validate-capability.sh"
    fields="$(cockpit-dispatch-action all-fields)" || return 1
    collected=""
    count=0
    while IFS= read -r line; do
        [[ -n "${line}" ]] || return 1
        # Fields: action, function, directory, realm.
        action="${line%%$'\t'*}"
        line="${line#*$'\t'}"
        line="${line#*$'\t'}"
        directory="${line%%$'\t'*}"
        cap="$(cockpit-load-capability "${directory}")" || return 1
        cockpit-validate-capability "${action}" "${cap}" && cap_rc=0 || cap_rc=$?
        [[ "${cap_rc}" -eq 0 || "${cap_rc}" -eq 2 ]] || return 1
        collected+="${cap}"$'\n'
        count=$((count + 1))
    done <<< "${fields}"
    (( count >= 1 )) || return 1
    printf '%s' "${collected}" | jq -c -s '{actions: .}'
}
