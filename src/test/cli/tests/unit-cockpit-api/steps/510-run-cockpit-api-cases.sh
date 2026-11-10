#!/usr/bin/env bash
# @file: 510-run-cockpit-api-cases.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/steps
# @group: test
# @category: step
# @description: Run Cockpit API cases.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the Cockpit handler cases.
# @details:
#   Session success is mocked and is not a live podshift login.
# @arg: $1 - the run folder.
# @stdout: NOTE with the counts, and one DETAIL line per case.
# @exitcode: 0 when every case passed, 2 when a case failed, 3 when jq is missing.
run-cockpit-api-cases() {
    local run_dir script rc
    run_dir="${1}"
    script="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/../scripts" && pwd -P)/run-cockpit-api-cases.sh"
    bash "${script}" "${run_dir}"
    rc=$?
    return "${rc}"
}
