#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-config
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-config
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Overview config module: lists TSV_ENV, any set TSV_NW1 to TSV_NW8, and user TSV_* keys.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F7B41D50E2A3:-}" ]]; then
    DIR_F7B41D50E2A3="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F7B41D50E2A3
fi

# @description: Lists TSV_ENV, any set TSV_NW1 to TSV_NW8, and any user-defined TSV_* keys.
# @details:
#   Built-in values come from the runtime and network loaders. User keys come from
#   tsv.conf, the file written by podshift config. TSV_ENV is always present; an
#   unset or empty value is null. Unset TSV_NW* and empty user keys are omitted. Each row has an
#   editable flag, and envSuggestions lists PODSHIFT_ENV_TYPES from main.conf.
# @stdout: one JSON object with a rows array and an envSuggestions array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-config() {
    local values var text i user_rows
    # shellcheck source=./fn/cockpit-overview-config-load.sh
    declare -F cockpit-overview-config-load >/dev/null || source "${DIR_F7B41D50E2A3}/fn/cockpit-overview-config-load.sh"
    # shellcheck source=./fn/cockpit-overview-config-tsv-text.sh
    declare -F cockpit-overview-config-tsv-text >/dev/null || source "${DIR_F7B41D50E2A3}/fn/cockpit-overview-config-tsv-text.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-config-user-rows.sh
    declare -F cockpit-overview-config-user-rows >/dev/null || source "${DIR_F7B41D50E2A3}/../../fn/overview/cockpit-overview-config-user-rows.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-config-rows.sh
    declare -F cockpit-overview-config-rows >/dev/null || source "${DIR_F7B41D50E2A3}/../../fn/overview/cockpit-overview-config-rows.sh"
    cockpit-overview-config-load
    values="{}"
    _overview_config_put() {
        local id text
        id="${1}"
        text="${2-}"
        if [[ -n "${text}" ]]; then
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" --arg value "${text}" '$values + {($id): $value}')" || return 1
        else
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" '$values + {($id): null}')" || return 1
        fi
    }
    _overview_config_put tsv_env "${TSV_ENV-}" || return 1
    for i in 1 2 3 4 5 6 7 8; do
        var="TSV_NW${i}"
        text="${!var-}"
        _overview_config_put "tsv_nw${i}" "${text}" || return 1
    done
    user_rows="$(cockpit-overview-config-user-rows "$(cockpit-overview-config-tsv-text)")" || user_rows="[]"
    cockpit-overview-config-rows "${values}" "${user_rows}" "${PODSHIFT_ENV_TYPES:-}"
}
