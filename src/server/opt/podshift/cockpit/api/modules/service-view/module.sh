#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/service-view
# @dest-dir: /opt/podshift/cockpit/api/modules/service-view
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Service view module: prints systemctl cat or systemctl status text of one podshift user service.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3512CBDFC57A:-}" ]]; then
    DIR_3512CBDFC57A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3512CBDFC57A
fi

# shellcheck source=../../fn/services/cockpit-services-args.sh
declare -F cockpit-services-args >/dev/null || source "${DIR_3512CBDFC57A}/../../fn/services/cockpit-services-args.sh"
# shellcheck source=../../fn/services/cockpit-services-loaded.sh
declare -F cockpit-services-loaded >/dev/null || source "${DIR_3512CBDFC57A}/../../fn/services/cockpit-services-loaded.sh"
# shellcheck source=../../fn/services/cockpit-services-view-result.sh
declare -F cockpit-services-view-result >/dev/null || source "${DIR_3512CBDFC57A}/../../fn/services/cockpit-services-view-result.sh"

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code.
cockpit-service-view-systemctl() {
    systemctl --user "$@"
}

# @description: Prints the unit file or the status of one loaded user service of the podshift user.
# @details:
#   The unit and mode are checked by cockpit-services-args. The unit must be one of the loaded
#   units of systemctl --user list-units --type=service --all (cockpit-services-loaded); else the
#   result is found false and nothing else runs. Mode unit runs systemctl --user cat. Mode status
#   runs systemctl --user status --no-pager --full --lines=10; exit 3 (not active, for example
#   inactive or failed) is not an error, exit 4 (no such unit) is found false. The result is built
#   by cockpit-services-view-result with the 131072-byte module output bound, so a longer text
#   gives tooLarge and size. The process runs in the podshift session, so systemctl --user talks
#   to that user's manager.
# @arg: $1 - action arguments as one JSON object with unit and mode.
# @stdout: one JSON object {unit, mode, found} plus text, or tooLarge and size.
# @exitcode: 0 when the result was written, 1 when the arguments are refused or systemctl fails.
cockpit-module-service-view() {
    local parsed unit mode raw text rc
    parsed="$(cockpit-services-args "${1-}" yes)" || return 1
    unit="${parsed%%$'\t'*}"
    mode="${parsed#*$'\t'}"
    raw="$(cockpit-service-view-systemctl list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null)" || return 1
    if ! cockpit-services-loaded "${raw}" | cut -f 1 | grep -F -x -q -- "${unit}"; then
        cockpit-services-view-result "${unit}" "${mode}" no 131072
        return
    fi
    if [[ "${mode}" == "unit" ]]; then
        # The x keeps trailing newlines; the subshell still exits with the systemctl code.
        text="$(cockpit-service-view-systemctl cat -- "${unit}" 2>/dev/null; rc=$?; printf x; exit "${rc}")" && rc=0 || rc=$?
    else
        text="$(cockpit-service-view-systemctl status --no-pager --full --lines=10 -- "${unit}" 2>/dev/null; rc=$?; printf x; exit "${rc}")" && rc=0 || rc=$?
    fi
    text="${text%x}"
    case "${mode}:${rc}" in
        unit:0|status:0|status:3) ;;
        status:4)
            cockpit-services-view-result "${unit}" "${mode}" no 131072
            return
            ;;
        *) return 1 ;;
    esac
    printf '%s' "${text}" | cockpit-services-view-result "${unit}" "${mode}" yes 131072
}
