#!/usr/bin/env bash
# @file: 540-verify-health-json-output.sh
# @source-dir: src/test/cli/tests/postinstall-health-output/steps
# @group: test
# @category: step
# @description: JSON output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the --json output is valid JSON, using python3 on this Mac.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if valid, 2 if not (PodShift problem), 3 if python3 is missing.
verify-health-json-output() {
    local run_dir json error
    run_dir="${1}"
    json="${run_dir}/health-output.json"
    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 not found"
        echo "Fix: xcode-select --install"
        return 3
    fi
    if error="$(python3 -m json.tool "${json}" 2>&1 >/dev/null)"; then
        write-log "${run_dir}" postinstall-health-output "JSON output: valid"
        return 0
    fi
    write-log "${run_dir}" postinstall-health-output "JSON output: invalid, ${error}"
    echo "The JSON output is not valid JSON"
    echo "DETAIL: ${error}"
    return 2
}
