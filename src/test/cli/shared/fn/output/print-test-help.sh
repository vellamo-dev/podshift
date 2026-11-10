#!/usr/bin/env bash
# @file: print-test-help.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the help of one test.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the tags, steps and run command of one test, then shows its readme.md with glow if there is one.
# @details:
#   The tags are read from its main.sh, and the steps are the ones for this OS.
# @arg: $1 - the cli folder.
# @arg: $2 - the OS, for example mac.
# @arg: $3 - the output mode: interactive or plain.
# @arg: $4 - the test name, for example install-rpm.
# @stdout: the test help.
# @stderr: why there is no help.
# @exitcode: 0 if shown, 1 if the test is unknown or the steps cannot be read, 3 if glow is not installed.
print-test-help() {
    local cli_dir os mode name test_dir steps step label need
    cli_dir="${1}"
    os="${2}"
    mode="${3}"
    name="${4}"
    test_dir="${cli_dir}/tests/${name}"
    if [[ ! "${name}" =~ ^[a-z0-9-]+$ || ! -f "${test_dir}/main.sh" ]]; then
        print-unknown-test "${cli_dir}" "${os}" "${name}"
        return 1
    fi
    steps="$(list-test-steps "${test_dir}" "${os}")" || return 1
    printf '\n▶ %s (%s)\n\n' "$(print-test-title "${test_dir}")" "${name}"
    printf '    %-11s %s\n' "Purpose:" "$(print-test-purpose "${test_dir}")"
    printf '    %-11s %s\n' "Platforms:" "$(sed -n 's/^# @platforms: //p' "${test_dir}/main.sh" | head -n 1)"
    label="Needs:"
    for need in $(list-test-needs "${test_dir}"); do
        printf '    %-11s %s\n' "${label}" "${need}"
        label=""
    done
    [[ -z "${label}" ]] || printf '    %-11s %s\n' "${label}" "none"
    label="Steps:"
    while IFS= read -r step; do
        [[ -n "${step}" ]] || continue
        printf '    %-11s %s %s\n' "${label}" "$(basename "${step}" | cut -d- -f1)" "$(sed -n 's/^# @description: //p' "${step}" | head -n 1)"
        label=""
    done <<<"${steps}"
    printf '    %-11s %s\n' "Run:" "./test ${name}"
    [[ -f "${test_dir}/readme.md" ]] || return 0
    echo
    show-markdown "${mode}" "${test_dir}/readme.md"
}
