#!/usr/bin/env bash
# @file: 110-require-jq.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/steps
# @group: test
# @category: step
# @description: Require jq.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops this test when jq is not installed.
# @arg: $1 - the run folder.
# @stdout: NOTE with the jq version, or a Fix line when jq is missing.
# @exitcode: 0 when jq is present, 3 when it is not.
require-jq() {
    local run_dir
    run_dir="${1}"
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq was not found"
        echo "Fix: install jq"
        return 3
    fi
    if declare -F write-log >/dev/null; then
        write-log "${run_dir}" unit-cockpit-api "jq $(jq --version)"
    fi
    echo "NOTE: $(jq --version)"
    return 0
}
