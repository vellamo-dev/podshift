#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/config-set
# @dest-dir: /opt/podshift/cockpit/api/modules/config-set
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Config set module: adds or changes one custom TSV_* key in the podshift user's tsv.conf.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_EBBAFDC00F4A:-}" ]]; then
    DIR_EBBAFDC00F4A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_EBBAFDC00F4A
fi

# @description: Checks one key and value with the podshift config rules, then saves them to tsv.conf.
# @details:
#   Runs in the podshift realm. The rules come from tsv-rules.conf (read-tsv-config-rules) and
#   the check is check-tsv-config-entry, the same as podshift config <key> <value>, and
#   update-tsv-conf writes the file. A refused entry is ok false with the error code and message;
#   the value is never echoed. Unreadable rules are ok false with RULES_UNAVAILABLE, and nothing
#   is saved. A write failure fails the action.
# @arg: $1 - action arguments as one JSON object with key and value.
# @stdout: one JSON object {key, ok} plus error and message when refused.
# @exitcode: 0 when the result was written, 1 when the arguments cannot be read or the file cannot be written.
cockpit-module-config-set() {
    local args key value rules problem
    args="${1-}"
    # shellcheck source=../../fn/config/cockpit-config-arg.sh
    declare -F cockpit-config-arg >/dev/null || source "${DIR_EBBAFDC00F4A}/../../fn/config/cockpit-config-arg.sh"
    # shellcheck source=../../fn/config/cockpit-config-result.sh
    declare -F cockpit-config-result >/dev/null || source "${DIR_EBBAFDC00F4A}/../../fn/config/cockpit-config-result.sh"
    key="$(cockpit-config-arg "${args}" key)" || return 1
    value="$(cockpit-config-arg "${args}" value)" || return 1
    # shellcheck source=../../../../fn/utils/read-tsv-config-rules.sh
    declare -F read-tsv-config-rules >/dev/null || source "${DIR_EBBAFDC00F4A}/../../../../fn/utils/read-tsv-config-rules.sh"
    if ! rules="$(read-tsv-config-rules 2>/dev/null)"; then
        cockpit-config-result "${key}" $'RULES_UNAVAILABLE\tThe config rules could not be read, so nothing was saved.'
        return
    fi
    # shellcheck source=../../../../fn/utils/check-tsv-config-entry.sh
    declare -F check-tsv-config-entry >/dev/null || source "${DIR_EBBAFDC00F4A}/../../../../fn/utils/check-tsv-config-entry.sh"
    if ! problem="$(check-tsv-config-entry "${key}" "${value}" "${rules}")"; then
        cockpit-config-result "${key}" "${problem}"
        return
    fi
    # shellcheck source=../../../../fn/utils/update-tsv-conf.sh
    declare -F update-tsv-conf >/dev/null || source "${DIR_EBBAFDC00F4A}/../../../../fn/utils/update-tsv-conf.sh"
    update-tsv-conf "${key}" "${value}" >/dev/null 2>&1 || return 1
    cockpit-config-result "${key}"
}
