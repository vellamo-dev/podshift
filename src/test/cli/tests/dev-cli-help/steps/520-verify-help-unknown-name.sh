#!/usr/bin/env bash
# @file: 520-verify-help-unknown-name.sh
# @source-dir: src/test/cli/tests/dev-cli-help/steps
# @group: test
# @category: step
# @description: Verify unknown help name.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift-help with a name that has no help file, like podshift --help no-such-command.
# @details:
#   It must exit 1 and print a message on stderr, and nothing on stdout.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if fine, 2 otherwise (PodShift problem).
verify-help-unknown-name() {
    local run_dir out err rc
    run_dir="${1}"
    err="${run_dir}/help-unknown.log"
    out="$("${BASH}" -c 'source "${1}/fn/common/podshift-help.sh"; podshift-help no-such-command' _ "${TST_PODSHIFT_DIR}" 2>"${err}")"
    rc=$?
    write-log "${run_dir}" dev-cli-help "Unknown name: exit ${rc}"
    if [[ "${rc}" -ne 1 ]]; then
        echo "Expected exit 1 for an unknown name, got ${rc}"
        return 2
    fi
    if [[ -n "${out}" ]]; then
        echo "An unknown name printed on stdout"
        return 2
    fi
    if [[ ! -s "${err}" ]]; then
        echo "An unknown name printed no message"
        return 2
    fi
    echo "NOTE: exit 1, $(head -n 1 "${err}")"
}
