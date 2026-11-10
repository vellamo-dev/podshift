#!/usr/bin/env bash
# @file: 520-verify-health-plain-output.sh
# @source-dir: src/test/cli/tests/postinstall-health-output/steps
# @group: test
# @category: step
# @description: Plain output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the plain output: no color codes, a head line, a Result line, and a Fix line under every note, warning and issue.
# @arg: $1 - the run folder.
# @stdout: each problem found.
# @exitcode: 0 if it looks right, 2 otherwise (PodShift problem).
verify-health-plain-output() {
    local run_dir plain rc no_fix
    run_dir="${1}"
    plain="${run_dir}/health-output-plain.log"
    rc=0
    grep -q $'\033' "${plain}" && { echo "The plain output has color codes"; rc=2; }
    grep -q '^▶ Health check (as ' "${plain}" || { echo "The plain output has no head line"; rc=2; }
    grep -q '^ *Result:$' "${plain}" || { echo "The plain output has no Result line"; rc=2; }
    no_fix="$(awk '/^ *Result:$/ { exit } want { if ($0 !~ /^ *Fix: /) print last; want = 0 } /^ *[ℹ⚠✘] / { want = 1; last = $0; sub(/^ +/, "", last) } END { if (want) print last }' "${plain}")"
    if [[ -n "${no_fix}" ]]; then
        echo "A note, warning or issue has no Fix line"
        printf '%s\n' "${no_fix}" | sed 's/^/DETAIL: /'
        rc=2
    fi
    write-log "${run_dir}" postinstall-health-output "Plain output check: exit ${rc}"
    return "${rc}"
}
