#!/usr/bin/env bash
# @file: 560-verify-units.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify systemd user units.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that each unit in data/expected-units.conf exists and, if marked yes, is enabled.
# @details:
#   Enabled means enabled for the podshift user.
# @arg: $1 - the run folder.
# @stdout: NOTE with the counts, DETAIL lines for units that fail.
# @exitcode: 0 if all pass, 2 otherwise.
verify-units() {
    local run_dir conf files wants unit enabled ok bad
    run_dir="${1}"
    conf="src/test/cli/tests/install-validate/data/expected-units.conf"
    files="$(vm-run "${TST_RPM_INSTALLER_VM}" ls -1 /usr/lib/systemd/user 2>/dev/null)"
    wants="$(vm-run "${TST_RPM_INSTALLER_VM}" ls -1 /home/podshift/.config/systemd/user/default.target.wants 2>/dev/null)"
    ok=0
    bad=0
    while read -r unit enabled; do
        [[ -n "${unit}" && "${unit}" != "#"* ]] || continue
        if ! printf '%s\n' "${files}" | grep -qxF "${unit}"; then
            echo "DETAIL: ✘ ${unit} (missing file)"
            bad=$((bad + 1))
        elif [[ "${enabled}" == "yes" ]] && ! printf '%s\n' "${wants}" | grep -qxF "${unit}"; then
            echo "DETAIL: ✘ ${unit} (not enabled)"
            bad=$((bad + 1))
        else
            ok=$((ok + 1))
        fi
    done <"${conf}"
    write-log "${run_dir}" install-validate "Check units: ${ok} ok, ${bad} failed"
    echo "NOTE: ${ok} ok, ${bad} failed"
    (( bad == 0 )) || return 2
}
