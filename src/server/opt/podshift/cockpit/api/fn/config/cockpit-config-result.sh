#!/usr/bin/env bash
# @file: cockpit-config-result.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/config
# @dest-dir: /opt/podshift/cockpit/api/fn/config
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the result object of a config-set, config-unset or env-set action.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {key, ok: true}, or {key, ok: false, error, message} from a CODE<tab>message problem line.
# @details:
#   The problem line is what check-tsv-config-entry and check-tsv-config-name print. An empty
#   problem means success. A problem without a tab is used as the code, with an empty message.
# @arg: $1 - the key name.
# @arg: $2 - optional problem line, CODE<tab>message.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 otherwise.
cockpit-config-result() {
    local key problem code message
    key="${1-}"
    problem="${2-}"
    if [[ -z "${problem}" ]]; then
        jq -n -c --arg key "${key}" '{key: $key, ok: true}'
        return
    fi
    code="${problem%%$'\t'*}"
    message=""
    if [[ "${problem}" == *$'\t'* ]]; then
        message="${problem#*$'\t'}"
    fi
    jq -n -c --arg key "${key}" --arg error "${code}" --arg message "${message}" \
        '{key: $key, ok: false, error: $error, message: $message}'
}
