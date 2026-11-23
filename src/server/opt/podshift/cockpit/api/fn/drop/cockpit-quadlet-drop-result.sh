#!/usr/bin/env bash
# @file: cockpit-quadlet-drop-result.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/drop
# @dest-dir: /opt/podshift/cockpit/api/fn/drop
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the result object of the quadlet-drop and quadlet-remove actions.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {name, ok: true}, or {name, ok: false, error, message} from a CODE<tab>message line.
# @details:
#   An empty problem means success; for quadlet-drop the name is then the final name in the drop
#   directory. A problem without a tab is used as the code, with an empty message.
# @arg: $1 - file name.
# @arg: $2 - optional problem line, CODE<tab>message.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 otherwise.
cockpit-quadlet-drop-result() {
    local name problem code message
    name="${1-}"
    problem="${2-}"
    if [[ -z "${problem}" ]]; then
        jq -n -c --arg name "${name}" '{name: $name, ok: true}'
        return
    fi
    code="${problem%%$'\t'*}"
    message=""
    if [[ "${problem}" == *$'\t'* ]]; then
        message="${problem#*$'\t'}"
    fi
    jq -n -c --arg name "${name}" --arg error "${code}" --arg message "${message}" \
        '{name: $name, ok: false, error: $error, message: $message}'
}
