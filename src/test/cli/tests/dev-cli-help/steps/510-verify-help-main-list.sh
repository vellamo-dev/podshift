#!/usr/bin/env bash
# @file: 510-verify-help-main-list.sh
# @source-dir: src/test/cli/tests/dev-cli-help/steps
# @group: test
# @category: step
# @description: Verify main help command list.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every module and shortcut is listed exactly once in help-main.log.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each problem.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-help-main-list() {
    local run_dir log name file lines found count bad
    run_dir="${1}"
    log="${run_dir}/help-main.log"
    # Only the command lines: indented lines after a "Run as" heading, up to the next empty line.
    lines="$(awk '/^Run as .*:$/ { on = 1; next } /^$/ { on = 0 } on' "${log}")"
    count=0
    bad=0
    while IFS=$'\t' read -r name file; do
        count=$((count + 1))
        found="$(printf '%s\n' "${lines}" | grep -c "^    ${name} ")"
        if [[ "${found}" -eq 0 ]]; then
            echo "DETAIL: ${name}: not listed"
            bad=$((bad + 1))
        elif [[ "${found}" -gt 1 ]]; then
            echo "DETAIL: ${name}: listed ${found} times"
            bad=$((bad + 1))
        elif ! printf '%s\n' "${lines}" | grep -q "^    ${name}  *[^ ]"; then
            echo "DETAIL: ${name}: no description"
            bad=$((bad + 1))
        fi
    done < <(podshift-command-list "${TST_PODSHIFT_DIR}")
    if [[ "$(printf '%s\n' "${lines}" | grep -c .)" -ne "${count}" ]]; then
        echo "DETAIL: the list has $(printf '%s\n' "${lines}" | grep -c .) lines for ${count} commands"
        bad=$((bad + 1))
    fi
    write-log "${run_dir}" dev-cli-help "Main help list: ${count} commands, ${bad} problems"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
