#!/usr/bin/env bash
# @file: 530-verify-ui-cockpit-package.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Verify Cockpit sees PodShift UI.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that cockpit-bridge --packages lists podshift, and notes when a dev bind overrides the package.
# @details:
#   postinstall-ui-dev-mount may bind the dev build at /usr/local/share/cockpit/podshift, which
#   Cockpit prefers over /usr/share. The check still passes, with a DETAIL note.
# @arg: $1 - the run folder.
# @stdout: NOTE listed or skipped, DETAIL about a dev bind, or the problem.
# @exitcode: 0 if listed or skipped, 2 otherwise.
verify-ui-cockpit-package() {
    local run_dir out line
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    out="$(vm-run "${TST_RPM_INSTALLER_VM}" cockpit-bridge --packages 2>&1)" || out=""
    line="$(printf '%s\n' "${out}" | awk '$1 == "podshift" || $1 == "podshift:"' | head -n 1)"
    if [[ -z "${line}" ]]; then
        write-log "${run_dir}" postinstall-ui-install "cockpit-bridge --packages: podshift not listed"
        echo "cockpit-bridge --packages does not list podshift"
        return 2
    fi
    write-log "${run_dir}" postinstall-ui-install "cockpit-bridge --packages: ${line}"
    if [[ "${line}" == *"/usr/local/share/cockpit/podshift"* ]]; then
        echo "DETAIL: Cockpit serves the dev build from /usr/local/share/cockpit/podshift, not the package."
    fi
    echo "NOTE: podshift listed"
}
