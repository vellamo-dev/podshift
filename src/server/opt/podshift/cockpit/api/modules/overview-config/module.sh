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

# shellcheck source=../../fn/overview/cockpit-overview-config-rows.sh
declare -F cockpit-overview-config-rows >/dev/null || source "${DIR_F7B41D50E2A3}/../../fn/overview/cockpit-overview-config-rows.sh"
# shellcheck source=../../fn/overview/cockpit-overview-config-user-rows.sh
declare -F cockpit-overview-config-user-rows >/dev/null || source "${DIR_F7B41D50E2A3}/../../fn/overview/cockpit-overview-config-user-rows.sh"

# @description: Loads TSV_ENV from the runtime config and derives TSV_NW1 to TSV_NW8.
# @details:
#   Reuses the existing loaders. A failure leaves the variables unset so the row value is null.
# @exitcode: 0 always.
cockpit-overview-config-load() {
    # shellcheck source=../../../../fn/load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_F7B41D50E2A3}/../../../../fn/load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime >/dev/null 2>&1 || true
    # Prefer a tree-relative loader when this is a source checkout; fall back to the install path.
    if ! declare -F load-podshift-conf-nw >/dev/null; then
        if [[ -f "${DIR_F7B41D50E2A3}/../../../../fn/load-podshift-conf-nw.sh" ]]; then
            # shellcheck source=../../../../fn/load-podshift-conf-nw.sh
            source "${DIR_F7B41D50E2A3}/../../../../fn/load-podshift-conf-nw.sh"
        elif [[ -f /opt/podshift/fn/load-podshift-conf-nw.sh ]]; then
            # shellcheck source=/opt/podshift/fn/load-podshift-conf-nw.sh
            source /opt/podshift/fn/load-podshift-conf-nw.sh
        fi
    fi
    if declare -F load-podshift-conf-nw >/dev/null; then
        load-podshift-conf-nw >/dev/null 2>&1 || true
    fi
}

# @description: Prints the text of the podshift user's tsv.conf, if it can be read.
# @details:
#   Uses PODSHIFT_TSV_CONF from the main configuration, usually
#   /home/podshift/.config/podshift/tsv.conf. A missing, unreadable or symlink file
#   prints nothing so only the built-in rows are shown.
# @stdout: the file text, or nothing.
# @exitcode: 0 always.
cockpit-overview-config-tsv-text() {
    local file
    if [[ -z "${PODSHIFT_TSV_CONF:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_F7B41D50E2A3}/../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    file="${PODSHIFT_TSV_CONF:-}"
    if [[ -n "${file}" && -f "${file}" && -r "${file}" && ! -L "${file}" ]]; then
        cat -- "${file}" 2>/dev/null || true
    fi
}

# @description: Lists TSV_ENV, any set TSV_NW1 to TSV_NW8, and any user-defined TSV_* keys.
# @details:
#   Built-in values come from the runtime and network loaders. User keys come from
#   tsv.conf, the file written by podshift config. TSV_ENV is always present; an
#   unset or empty value is null. Unset TSV_NW* and empty user keys are omitted.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-config() {
    local values var text i user_rows
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
    cockpit-overview-config-rows "${values}" "${user_rows}"
}
