#!/usr/bin/env bash
# @file: drop-history-message.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Builds one drop history record as compact JSON, the message of the podshift-drop-history journal tag.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_19DA9C4AB400:-}" ]]; then
    DIR_19DA9C4AB400="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_19DA9C4AB400
fi

# @description: Prints {id, name, status} plus reason and description when they are not empty.
# @details:
#   id is the drop ID, a UUIDv7 (is-valid-uuid7), the same for every step of one drop.
#   status is one of accepted, validated, installing, installed, unchanged, failed or refused.
#   name is cut to 255 characters, reason and description to 200.
# @arg: $1 - drop ID.
# @arg: $2 - dropped file name, for example web.container or shop.zip.
# @arg: $3 - status.
# @arg: $4 - optional reason, for a failed or refused item.
# @arg: $5 - optional Description of the Quadlet.
# @stdout: one JSON object on one line.
# @exitcode: 0 when it was printed, 1 when the ID is not valid, the name is empty, the status is unknown or jq fails.
drop-history-message() {
    local id name status reason description
    id="${1-}"
    name="${2-}"
    status="${3-}"
    reason="${4-}"
    description="${5-}"
    # shellcheck source=../utils/is-valid-uuid7.sh
    declare -F is-valid-uuid7 >/dev/null || source "${DIR_19DA9C4AB400}/../utils/is-valid-uuid7.sh"
    is-valid-uuid7 "${id}" || return 1
    [[ -n "${name}" ]] || return 1
    case "${status}" in
        accepted|validated|installing|installed|unchanged|failed|refused) ;;
        *) return 1 ;;
    esac
    jq -n -c --arg id "${id}" --arg name "${name:0:255}" --arg status "${status}" --arg reason "${reason:0:200}" \
        --arg description "${description:0:200}" \
        '{id: $id, name: $name, status: $status}
        + (if $reason == "" then {} else {reason: $reason} end)
        + (if $description == "" then {} else {description: $description} end)'
}
