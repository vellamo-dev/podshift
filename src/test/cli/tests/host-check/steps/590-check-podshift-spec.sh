#!/usr/bin/env bash
# @file: 590-check-podshift-spec.sh
# @source-dir: src/test/cli/tests/host-check/steps
# @group: test
# @category: step
# @description: podshift.spec found.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that podshift.spec is in the repository root.
# @stdout: the problem and how to fix it, if any.
# @arg: $1 - the run folder.
# @exitcode: 0 if found, 3 otherwise (cannot run here).
check-podshift-spec() {
    local run_dir
    run_dir="${1}"
    write-log "${run_dir}" host-check "podshift.spec: $(pwd)/podshift.spec"
    [[ -f podshift.spec ]] && return 0
    echo "podshift.spec not found in $(pwd)"
    echo "Fix: run the tests from a full PodShift checkout"
    return 3
}
