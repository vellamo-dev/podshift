#!/usr/bin/env bash
# @file: 530-verify-shortcuts.sh
# @source-dir: src/test/cli/tests/lint-cli-modules/steps
# @group: test
# @category: step
# @description: Verify shortcut names.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that no script in shortcuts/root or shortcuts/rootless has the same name as a CLI module or alias.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each clash.
# @exitcode: 0 if no clashes, 2 otherwise (PodShift problem).
verify-shortcuts() {
    local run_dir cli_dir names script name count bad
    run_dir="${1}"
    cli_dir="${TST_PODSHIFT_DIR}/cli"
    count=0
    bad=0
    names=" $(ls "${cli_dir}/modules" 2>/dev/null | xargs) $(sed -e 's/#.*//' -e 's/=.*//' "${cli_dir}/aliases.conf" 2>/dev/null | xargs) "
    for script in "${TST_PODSHIFT_DIR}"/shortcuts/root/*.sh "${TST_PODSHIFT_DIR}"/shortcuts/rootless/*.sh; do
        [[ -f "${script}" ]] || continue
        name="$(basename "${script}" .sh)"
        count=$((count + 1))
        if [[ "${names}" == *" ${name} "* ]]; then
            echo "DETAIL: ${script#"${TST_PODSHIFT_DIR}/"}: same name as a module or alias"
            bad=$((bad + 1))
        fi
    done
    write-log "${run_dir}" lint-cli-modules "Shortcuts: ${count} checked, ${bad} clashes"
    echo "NOTE: ${count} checked, ${bad} not OK"
    (( bad == 0 )) || return 2
}
