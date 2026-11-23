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

# @description: Runs the PodShift health checks and prints the Cockpit health-check object.
# @details:
#   The checks are the same functions as the CLI. The output is grouped rows plus a summary,
#   not the CLI report text.
# @stdout: one JSON object with groups and summary.
# @exitcode: 0 when the object was written, 1 when no checks ran or the payload could not be built.
cockpit-module-health-check() {
    local results verdict_line cli_dir
    cli_dir="${DIR_C8F31A94D2E7}/../../../../cli/modules/health-check"
    # shellcheck source=./fn/cockpit-health-check-run.sh
    declare -F cockpit-health-check-run >/dev/null || source "${DIR_C8F31A94D2E7}/fn/cockpit-health-check-run.sh"
    results="$(cockpit-health-check-run)"
    results="${results%$'\n'}"
    if [[ -z "${results}" ]]; then
        return 1
    fi
    # shellcheck source=../../../../cli/modules/health-check/fn/health-verdict.sh
    declare -F health-verdict >/dev/null || source "${cli_dir}/fn/health-verdict.sh"
    verdict_line="$(health-verdict "${results}")"
    # shellcheck source=../../fn/cockpit-health-check-data.sh
    declare -F cockpit-health-check-data >/dev/null || source "${DIR_C8F31A94D2E7}/../../fn/cockpit-health-check-data.sh"
    cockpit-health-check-data "${results}" "${verdict_line}" "${cli_dir}/groups.conf"
}
