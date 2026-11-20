#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/env-set
# @dest-dir: /opt/podshift/cockpit/api/modules/env-set
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Environment tag set module: sets TSV_ENV in the runtime configuration while it is unset.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_0CC910242981:-}" ]]; then
    DIR_0CC910242981="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_0CC910242981
fi

# @description: Checks the tag, refuses when TSV_ENV is already set, then saves it to runtime.conf.
# @details:
#   Runs in the root realm, because only root may write /var/lib/podshift/runtime.conf. The tag
#   rule is is-valid-env-tag, the same as podshift env --set. The current value is read with
#   load-podshift-conf-runtime, as podshift env shows it. A set value is ok false with
#   ALREADY_SET, so the UI can set the tag only once; root can still change it with
#   sudo podshift env --set. update-podshift-conf writes the file. A load or write failure fails
#   the action.
# @arg: $1 - action arguments as one JSON object with value.
# @stdout: one JSON object {key: "TSV_ENV", ok} plus error and message when refused.
# @exitcode: 0 when the result was written, 1 when the arguments or config cannot be read or the file cannot be written.
cockpit-module-env-set() {
    local args value
    args="${1-}"
    # shellcheck source=../../fn/config/cockpit-config-arg.sh
    declare -F cockpit-config-arg >/dev/null || source "${DIR_0CC910242981}/../../fn/config/cockpit-config-arg.sh"
    # shellcheck source=../../fn/config/cockpit-config-result.sh
    declare -F cockpit-config-result >/dev/null || source "${DIR_0CC910242981}/../../fn/config/cockpit-config-result.sh"
    value="$(cockpit-config-arg "${args}" value)" || return 1
    # shellcheck source=../../../../fn/utils/is-valid-env-tag.sh
    declare -F is-valid-env-tag >/dev/null || source "${DIR_0CC910242981}/../../../../fn/utils/is-valid-env-tag.sh"
    if ! is-valid-env-tag "${value}"; then
        cockpit-config-result TSV_ENV $'INVALID_TAG\tInvalid tag. Use 1 to 128 characters of a-z, A-Z, 0-9, _, . and -, not starting with . or -.'
        return
    fi
    unset TSV_ENV
    # shellcheck source=../../../../fn/load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_0CC910242981}/../../../../fn/load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime >/dev/null 2>&1 || return 1
    if [[ -n "${TSV_ENV:-}" ]]; then
        cockpit-config-result TSV_ENV $'ALREADY_SET\tTSV_ENV is already set. Change it with: sudo podshift env --set <tag>'
        return
    fi
    # shellcheck source=../../../../fn/utils/update-podshift-conf.sh
    declare -F update-podshift-conf >/dev/null || source "${DIR_0CC910242981}/../../../../fn/utils/update-podshift-conf.sh"
    update-podshift-conf TSV_ENV "${value}" >/dev/null 2>&1 || return 1
    cockpit-config-result TSV_ENV
}
