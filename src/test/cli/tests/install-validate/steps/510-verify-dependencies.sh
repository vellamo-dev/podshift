#!/usr/bin/env bash
# @file: 510-verify-dependencies.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify dependencies installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every package in the Requires line of podshift.spec is installed in the VM.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and the missing packages.
# @exitcode: 0 if all are installed, 2 otherwise.
verify-dependencies() {
    local run_dir requires missing
    run_dir="${1}"
    read -r -a requires <<<"$(sed -n 's/^Requires:[[:space:]]*//p' podshift.spec | head -n 1)"
    (( ${#requires[@]} > 0 )) || { echo "No Requires line in podshift.spec"; return 1; }
    missing="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q "${requires[@]}" 2>&1 | grep 'is not installed')"
    if [[ -n "${missing}" ]]; then
        write-log "${run_dir}" install-validate "Check dependencies: missing $(printf '%s' "${missing}" | grep -c .)"
        echo "${missing}"
        return 2
    fi
    write-log "${run_dir}" install-validate "Check dependencies: ${#requires[@]} installed"
    echo "NOTE: ${#requires[@]} installed"
}
