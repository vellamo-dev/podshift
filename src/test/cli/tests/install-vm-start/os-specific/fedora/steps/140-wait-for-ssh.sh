#!/usr/bin/env bash
# @file: 140-wait-for-ssh.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Wait for SSH in RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Waits until the RPM installer VM has an IP address and answers over SSH, up to TST_RPM_INSTALLER_BOOT_TIMEOUT seconds.
# @details:
#   It tries every 2 seconds.
# @arg: $1 - the run folder.
# @stdout: NOTE with the IP address. The test shows how long it took.
# @exitcode: 0 if the VM answers, 1 otherwise.
wait-for-ssh() {
    local run_dir ip start
    run_dir="${1}"
    # Own start time: resetting SECONDS would break the step time the test shows.
    start="${SECONDS}"
    until vm-run "${TST_RPM_INSTALLER_VM}" true 2>/dev/null; do
        if (( SECONDS - start >= TST_RPM_INSTALLER_BOOT_TIMEOUT )); then
            ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
            write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: no SSH after $((SECONDS - start))s, IP ${ip:-none}"
            echo "The VM ${TST_RPM_INSTALLER_VM} did not answer over SSH after $((SECONDS - start))s (IP ${ip:-none})"
            return 1
        fi
        sleep 2
    done
    ip="$(vm-ip "${TST_RPM_INSTALLER_VM}")"
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: SSH answers at ${ip} after $((SECONDS - start))s"
    echo "NOTE: ${ip}"
}
