#!/usr/bin/env bash
# @file: 520-verify-vm-os.sh
# @source-dir: src/test/cli/tests/install-vm-start/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM OS.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM runs the Fedora version from TST_FEDORA_VERSION.
# @arg: $1 - the run folder.
# @stdout: NOTE with the Fedora version.
# @exitcode: 0 if the version matches, 1 otherwise.
verify-vm-os() {
    local run_dir release id version
    run_dir="${1}"
    release="$(vm-run "${TST_RPM_INSTALLER_VM}" cat /etc/os-release 2>/dev/null)"
    id="$(printf '%s\n' "${release}" | sed -n 's/^ID=//p' | tr -d '"')"
    version="$(printf '%s\n' "${release}" | sed -n 's/^VERSION_ID=//p' | tr -d '"')"
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: OS ${id:-unknown} ${version:-unknown}"
    if [[ "${id}" == "fedora" && "${version}" == "${TST_FEDORA_VERSION}" ]]; then
        echo "NOTE: Fedora ${version}"
        return 0
    fi
    echo "Expected Fedora ${TST_FEDORA_VERSION}, found ${id:-unknown} ${version:-unknown}"
    return 1
}
