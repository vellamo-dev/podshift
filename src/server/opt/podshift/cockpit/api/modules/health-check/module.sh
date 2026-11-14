#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/health-check
# @dest-dir: /opt/podshift/cockpit/api/modules/health-check
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Health-check module: runs the CLI health checks and returns grouped Cockpit data.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C8F31A94D2E7:-}" ]]; then
    DIR_C8F31A94D2E7="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C8F31A94D2E7
fi

# shellcheck source=../../fn/cockpit-health-check-data.sh
declare -F cockpit-health-check-data >/dev/null || source "${DIR_C8F31A94D2E7}/../../fn/cockpit-health-check-data.sh"

if [[ -z "${DIR_HEALTH_CHECK_MODULE:-}" ]]; then
    DIR_HEALTH_CHECK_MODULE="$(CDPATH='' cd -P -- "${DIR_C8F31A94D2E7}/../../../../cli/modules/health-check" && pwd -P)"
    readonly DIR_HEALTH_CHECK_MODULE
fi

# shellcheck source=../../../../cli/modules/health-check/fn/health-caller.sh
declare -F health-caller >/dev/null || source "${DIR_HEALTH_CHECK_MODULE}/fn/health-caller.sh"
# shellcheck source=../../../../cli/modules/health-check/fn/health-result.sh
declare -F health-result >/dev/null || source "${DIR_HEALTH_CHECK_MODULE}/fn/health-result.sh"
# shellcheck source=../../../../cli/modules/health-check/fn/health-verdict.sh
declare -F health-verdict >/dev/null || source "${DIR_HEALTH_CHECK_MODULE}/fn/health-verdict.sh"

# @description: Runs every CLI health check and prints one result line per check, with fix text.
# @details:
#   Uses the same health-result and check scripts as `podshift health-check`. A sixth field holds
#   the check's @fix text for INFO, WARN and FAIL, or is empty otherwise.
# @stdout: result lines: group, id, title, status, detail, fix.
# @exitcode: 0 always.
cockpit-health-check-run() {
    local script group caller line group_name id title status detail fix
    caller="$(health-caller)"
    for script in "${DIR_HEALTH_CHECK_MODULE}/checks"/*/*.sh; do
        [[ -f "${script}" ]] || continue
        group="$(basename "$(dirname "${script}")")"
        group="${group#*-}"
        line="$(health-result "${script}" "${group}" "${caller}")"
        IFS=$'\t' read -r group_name id title status detail <<< "${line}"
        fix=""
        case "${status}" in
            INFO|WARN|FAIL)
                fix="$(grep -m1 '^# @fix:' "${script}" 2>/dev/null | sed 's/^# @fix: //')"
                ;;
        esac
        printf '%s\t%s\n' "${line}" "${fix}"
    done
    return 0
}

# @description: Runs the PodShift health checks and prints the Cockpit health-check object.
# @details:
#   The checks are the same functions as the CLI. The output is grouped rows plus a summary,
#   not the CLI report text.
# @stdout: one JSON object with groups and summary.
# @exitcode: 0 when the object was written, 1 when no checks ran or the payload could not be built.
cockpit-module-health-check() {
    local results verdict_line
    results="$(cockpit-health-check-run)"
    results="${results%$'\n'}"
    if [[ -z "${results}" ]]; then
        return 1
    fi
    verdict_line="$(health-verdict "${results}")"
    cockpit-health-check-data "${results}" "${verdict_line}" "${DIR_HEALTH_CHECK_MODULE}/groups.conf"
}

