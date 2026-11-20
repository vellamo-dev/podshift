#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/config-unset
# @dest-dir: /opt/podshift/cockpit/api/modules/config-unset
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Config unset module: removes one custom TSV_* key from the podshift user's tsv.conf.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E148D7762F6B:-}" ]]; then
    DIR_E148D7762F6B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E148D7762F6B
fi

# @description: Checks one key with the podshift config name rules, then removes it from tsv.conf.
# @details:
#   Runs in the podshift realm. The check is check-tsv-config-name and the removal is
#   remove-tsv-conf, the same as podshift config --unset <key>. The secret rules are not checked,
#   so a key saved before them can be removed. A key that is not in the file is ok false with
#   NOT_SET. A write failure fails the action.
# @arg: $1 - action arguments as one JSON object with key.
# @stdout: one JSON object {key, ok} plus error and message when refused.
# @exitcode: 0 when the result was written, 1 when the arguments cannot be read or the file cannot be written.
cockpit-module-config-unset() {
    local args key problem rc
    args="${1-}"
    # shellcheck source=../../fn/config/cockpit-config-arg.sh
    declare -F cockpit-config-arg >/dev/null || source "${DIR_E148D7762F6B}/../../fn/config/cockpit-config-arg.sh"
    # shellcheck source=../../fn/config/cockpit-config-result.sh
    declare -F cockpit-config-result >/dev/null || source "${DIR_E148D7762F6B}/../../fn/config/cockpit-config-result.sh"
    key="$(cockpit-config-arg "${args}" key)" || return 1
    # shellcheck source=../../../../fn/utils/check-tsv-config-name.sh
    declare -F check-tsv-config-name >/dev/null || source "${DIR_E148D7762F6B}/../../../../fn/utils/check-tsv-config-name.sh"
    if ! problem="$(check-tsv-config-name "${key}")"; then
        cockpit-config-result "${key}" "${problem}"
        return
    fi
    # shellcheck source=../../../../fn/utils/remove-tsv-conf.sh
    declare -F remove-tsv-conf >/dev/null || source "${DIR_E148D7762F6B}/../../../../fn/utils/remove-tsv-conf.sh"
    remove-tsv-conf "${key}" >/dev/null 2>&1 && rc=0 || rc=$?
    case "${rc}" in
        0) cockpit-config-result "${key}" ;;
        2) cockpit-config-result "${key}" "NOT_SET"$'\t'"${key} is not set." ;;
        *) return 1 ;;
    esac
}
