#!/usr/bin/env bash
# @file: 550-verify-preset.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify systemd preset.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the PodShift user preset exists and enables the PodShift path and timer units.
# @details:
#   The units are podshift-drop.path, podshift-drop-safety.timer, podshift-qdl-validate.path and
#   podshift-qdl-install.path.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if all is well, 2 otherwise.
verify-preset() {
    local run_dir preset content unit missing
    run_dir="${1}"
    preset="/usr/lib/systemd/user-preset/90-podshift.preset"
    content="$(vm-run "${TST_RPM_INSTALLER_VM}" cat "${preset}" 2>/dev/null)"
    if [[ -z "${content}" ]]; then
        write-log "${run_dir}" install-validate "Check preset: missing"
        echo "${preset} is missing or empty"
        return 2
    fi
    missing=0
    for unit in podshift-drop.path podshift-drop-safety.timer podshift-qdl-validate.path podshift-qdl-install.path; do
        printf '%s\n' "${content}" | grep -qE "^enable[[:space:]]+${unit}" && continue
        echo "${preset} does not enable ${unit}"
        missing=$((missing + 1))
    done
    write-log "${run_dir}" install-validate "Check preset: ${missing} units not enabled"
    (( missing == 0 )) || return 2
}
