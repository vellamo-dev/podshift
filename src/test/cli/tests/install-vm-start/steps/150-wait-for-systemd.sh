#!/usr/bin/env bash
# @file: 150-wait-for-systemd.sh
# @source-dir: src/test/cli/tests/install-vm-start/steps
# @group: test
# @category: step
# @description: Wait for systemd.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Waits until systemd in the RPM installer VM has finished starting, up to TST_RPM_INSTALLER_BOOT_TIMEOUT seconds.
# @details:
#   It asks every 2 seconds, because right after boot systemd does not answer at all for a moment.
# @arg: $1 - the run folder.
# @stdout: NOTE with the systemd state, and DETAIL lines with the failed units.
# @exitcode: 0 if systemd is running, 1 if it is degraded, still starting or not answering.
wait-for-systemd() {
    local run_dir state unit start
    run_dir="${1}"
    # Own start time: resetting SECONDS would break the step time the test shows.
    start="${SECONDS}"
    while :; do
        state="$(vm-run "${TST_RPM_INSTALLER_VM}" systemctl is-system-running 2>/dev/null)"
        case "${state}" in
            running|degraded|maintenance|stopping|offline) break ;;
        esac
        (( SECONDS - start < TST_RPM_INSTALLER_BOOT_TIMEOUT )) || break
        sleep 2
    done
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: systemd ${state:-no answer} after $((SECONDS - start))s"
    if [[ "${state}" == "running" ]]; then
        echo "NOTE: running"
        return 0
    fi
    echo "NOTE: ${state:-no answer}"
    while read -r unit; do
        [[ -z "${unit}" ]] || echo "DETAIL: failed unit ${unit}"
    done < <(vm-run "${TST_RPM_INSTALLER_VM}" systemctl list-units --failed --plain --no-legend 2>/dev/null | awk '{ print $1 }')
    echo "systemd in the VM is ${state:-not answering} after $((SECONDS - start))s"
    return 1
}
