#!/usr/bin/env bash
# @file: vm-stop-if-running.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Stops a test VM if it is running, without removing it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the VM if it is running and logs it, without removing it.
# @details:
#   A clean shutdown is tried first, and the helper waits up to TST_RPM_INSTALLER_STOP_TIMEOUT
#   seconds. If the VM is still running, it is forced off. The base VM named in
#   TST_RPM_INSTALLER_BASE is refused, when that name is set. A VM that is not running is left as it is.
# @arg: $1 - the run folder.
# @arg: $2 - the log name, for example install-vm-stop.
# @arg: $3 - the VM name.
# @stdout: NOTE stopped, not running or forced, or the problem.
# @exitcode: 0 if it is not running anymore, 1 otherwise.
vm-stop-if-running() {
    local run_dir name vm waited timeout
    run_dir="${1}"
    name="${2}"
    vm="${3}"
    if [[ -n "${TST_RPM_INSTALLER_BASE:-}" && "${vm}" == "${TST_RPM_INSTALLER_BASE}" ]]; then
        echo "The base VM ${vm} must not be stopped this way"
        return 1
    fi
    if ! vm-running "${vm}"; then
        echo "NOTE: not running"
        return 0
    fi
    vm-virsh shutdown "${vm}" >/dev/null 2>&1 || true
    waited=0
    timeout="${TST_RPM_INSTALLER_STOP_TIMEOUT:-60}"
    while vm-running "${vm}" && [[ "${waited}" -lt "${timeout}" ]]; do
        sleep 2
        waited=$((waited + 2))
    done
    if ! vm-running "${vm}"; then
        write-log "${run_dir}" "${name}" "VM ${vm}: stopped"
        echo "NOTE: stopped"
        return 0
    fi
    if vm-virsh destroy "${vm}" >/dev/null 2>&1 && ! vm-running "${vm}"; then
        write-log "${run_dir}" "${name}" "VM ${vm}: forced"
        echo "NOTE: forced"
        return 0
    fi
    echo "The VM ${vm} could not be stopped"
    return 1
}
