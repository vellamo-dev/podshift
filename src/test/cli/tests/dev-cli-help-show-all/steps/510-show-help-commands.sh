#!/usr/bin/env bash
# @file: 510-show-help-commands.sh
# @source-dir: src/test/cli/tests/dev-cli-help-show-all/steps
# @group: test
# @category: step
# @description: Command help.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift-help for every module and shortcut from the source folder and prints it as DETAIL lines.
# @details:
#   It works like podshift --help <command>, saves it all to help-show-all.log, and puts each
#   command under a heading. A command without a help file shows (no help file).
# @arg: $1 - the run folder.
# @stdout: NOTE with the counts, and the help as DETAIL lines.
# @exitcode: 0 if every help ran or had no file, 2 if a help failed otherwise (PodShift problem).
show-help-commands() {
    local run_dir log name file out rc count shown missing failed
    run_dir="${1}"
    log="${run_dir}/help-show-all.log"
    count=0
    shown=0
    missing=0
    failed=0
    : >"${log}"
    while IFS=$'\t' read -r name file; do
        count=$((count + 1))
        {
            echo "── podshift --help ${name} ──"
            if [[ ! -f "${TST_PODSHIFT_DIR}/doc/help/${name}.md" && ! -f "${TST_PODSHIFT_DIR}/doc/help/${name}.txt" ]]; then
                echo "(no help file)"
                missing=$((missing + 1))
            else
                out="$("${BASH}" -c 'source "${1}/fn/common/podshift-help.sh"; podshift-help "${2}"' _ "${TST_PODSHIFT_DIR}" "${name}" </dev/null 2>&1)"
                rc=$?
                # glow pads lines with spaces, so remove trailing spaces. It runs with </dev/null above, because glow reads stdin when it is not a terminal.
                printf '%s\n' "${out}" | sed 's/[[:space:]]*$//'
                if [[ "${rc}" -eq 0 ]]; then
                    shown=$((shown + 1))
                else
                    echo "(failed with exit ${rc})"
                    failed=$((failed + 1))
                fi
            fi
            echo
        } >>"${log}"
    done < <(podshift-command-list "${TST_PODSHIFT_DIR}")
    write-log "${run_dir}" dev-cli-help-show-all "Command help: ${count} commands, ${shown} shown, ${missing} without help, ${failed} failed"
    [[ "${failed}" -eq 0 ]] || echo "${failed} help pages failed to show"
    echo "NOTE: ${count} commands, ${shown} shown, ${missing} without help, saved in help-show-all.log"
    sed 's/^/DETAIL: /' "${log}"
    [[ "${failed}" -eq 0 ]] || return 2
}
