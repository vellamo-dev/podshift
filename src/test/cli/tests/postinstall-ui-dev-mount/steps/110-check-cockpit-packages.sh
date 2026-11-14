#!/usr/bin/env bash
# @file: 110-check-cockpit-packages.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Check Cockpit packages.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that cockpit-ws, cockpit-bridge and cockpit-system are already installed in the installer VM.
# @details:
#   It does not install packages. The installer image is expected to provide them.
# @arg: $1 - the run folder.
# @stdout: NOTE with the packages, or the missing names and how to fix it.
# @exitcode: 0 if all are installed, 3 if one is missing or the VM is not running.
check-cockpit-packages() {
    local run_dir pkg out
    local -a pkgs missing
    run_dir="${1}"
    pkgs=(cockpit-ws cockpit-bridge cockpit-system)
    missing=()
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
        echo "Fix: ./test bundle-ui-dev-mount"
        return 3
    fi
    for pkg in "${pkgs[@]}"; do
        if out="$(vm-run "${TST_RPM_INSTALLER_VM}" rpm -q "${pkg}" 2>&1)"; then
            write-log "${run_dir}" postinstall-ui-dev-mount "rpm -q ${pkg}: ${out}"
        else
            write-log "${run_dir}" postinstall-ui-dev-mount "rpm -q ${pkg}: ${out}"
            missing+=("${pkg}")
        fi
    done
    if [[ "${#missing[@]}" -ne 0 ]]; then
        echo "Cockpit packages are missing: ${missing[*]}"
        echo "Fix: ./test install-image"
        return 3
    fi
    echo "NOTE: ${pkgs[*]}"
}
