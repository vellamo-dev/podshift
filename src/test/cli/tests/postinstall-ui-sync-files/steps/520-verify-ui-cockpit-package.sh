#!/usr/bin/env bash
# @file: 520-verify-ui-cockpit-package.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files/steps
# @group: test
# @category: step
# @description: Verify Cockpit sees PodShift UI.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that cockpit-bridge --packages lists podshift after the sync.
# @arg: $1 - the run folder.
# @stdout: NOTE listed or skipped, or the problem.
# @exitcode: 0 if listed or skipped, 2 otherwise.
verify-ui-cockpit-package() {
    local run_dir dest out line
    run_dir="${1}"
    dest=/usr/share/cockpit/podshift
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        echo "NOTE: skipped"
        return 0
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${dest}" \
        || vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q /usr/local/share/cockpit/podshift; then
        echo "NOTE: skipped"
        return 0
    fi
    out="$(vm-run "${TST_RPM_INSTALLER_VM}" cockpit-bridge --packages 2>&1)" || out=""
    line="$(printf '%s\n' "${out}" | awk '$1 == "podshift" || $1 == "podshift:"' | head -n 1)"
    if [[ -z "${line}" ]]; then
        write-log "${run_dir}" postinstall-ui-sync-files "cockpit-bridge --packages: podshift not listed"
        echo "cockpit-bridge --packages does not list podshift"
        return 2
    fi
    write-log "${run_dir}" postinstall-ui-sync-files "cockpit-bridge --packages: ${line}"
    echo "NOTE: podshift listed"
}
