#!/usr/bin/env bash
# @file: 510-verify-health-terminal-output.sh
# @source-dir: src/test/cli/tests/postinstall-health-output/steps
# @group: test
# @category: step
# @description: Terminal output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the terminal output uses colors and matches the plain output.
# @arg: $1 - the run folder.
# @stdout: the problem and DETAIL lines with the first difference, if any.
# @exitcode: 0 if it looks right, 2 otherwise (PodShift problem).
verify-health-terminal-output() {
    local run_dir tty_log screen plain diff_out
    run_dir="${1}"
    tty_log="${run_dir}/health-output-tty.log"
    screen="${run_dir}/health-output-screen.log"
    plain="${run_dir}/health-output-plain.log"
    if ! grep -q $'\033\[' "${tty_log}"; then
        write-log "${run_dir}" postinstall-health-output "Terminal output: no colors"
        echo "The terminal output has no colors"
        return 2
    fi
    # What a person sees: for each line, the text after the last carriage return, without color codes.
    LC_ALL=C awk '{ sub(/\r$/, ""); n = split($0, part, "\r"); print part[n] }' "${tty_log}" \
        | LC_ALL=C sed -e $'s/\033\\[[0-9;]*[A-Za-z]//g' -e 's/[[:space:]]*$//' >"${screen}"
    if diff_out="$(diff <(sed 's/[[:space:]]*$//' "${plain}") "${screen}")"; then
        write-log "${run_dir}" postinstall-health-output "Terminal output: colors, same lines as plain"
        return 0
    fi
    write-log "${run_dir}" postinstall-health-output "Terminal output: differs from plain"
    echo "The terminal output does not show the same lines as the plain output"
    printf '%s\n' "${diff_out}" | head -n 6 | sed 's/^/DETAIL: /'
    return 2
}
