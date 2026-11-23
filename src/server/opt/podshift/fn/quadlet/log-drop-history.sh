#!/usr/bin/env bash
# @file: log-drop-history.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Writes one drop history record to the journal with the podshift-drop-history tag.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1FF640D08294:-}" ]]; then
    DIR_1FF640D08294="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1FF640D08294
fi

# @description: Logs {id, name, status, reason, description} as JSON with logger -t podshift-drop-history.
# @details:
#   The Description comes from the [Unit] section of the given Quadlet file, when it is a readable
#   file and the name does not end in .zip. The record is built by drop-history-message. The
#   Cockpit quadlet-drop-history action reads these records. A failure is ignored, so the pipeline
#   never stops for the history.
# @arg: $1 - drop ID, a UUIDv7; a missing or invalid ID logs nothing.
# @arg: $2 - dropped file name, for example web.container or shop.zip.
# @arg: $3 - status: accepted, validated, installing, installed, unchanged, failed or refused.
# @arg: $4 - optional reason.
# @arg: $5 - optional Quadlet file to read the Description from.
# @exitcode: 0 always.
log-drop-history() {
    local id name status reason file description message
    id="${1-}"
    name="${2-}"
    status="${3-}"
    reason="${4-}"
    file="${5-}"
    description=""
    if [[ -n "${file}" && -f "${file}" && "${name}" != *.zip ]]; then
        # shellcheck source=./get-quadlet-ini.sh
        declare -F get-quadlet-ini >/dev/null || source "${DIR_1FF640D08294}/get-quadlet-ini.sh"
        description="$(get-quadlet-ini "${file}" Unit Description 2>/dev/null)" || description=""
    fi
    # shellcheck source=./drop-history-message.sh
    declare -F drop-history-message >/dev/null || source "${DIR_1FF640D08294}/drop-history-message.sh"
    message="$(drop-history-message "${id}" "${name}" "${status}" "${reason}" "${description}")" || return 0
    logger -t podshift-drop-history -p info "${message}" 2>/dev/null || true
    return 0
}
