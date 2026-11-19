#!/usr/bin/env bash
# @file: vm-start-if-stopped.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Starts an existing test VM if it is stopped.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Starts the VM with libvirt if it exists and is stopped, and logs it, without creating it.
# @details:
#   The base VM named in TST_RPM_INSTALLER_BASE is refused, when that name is set. A VM that is
#   already running is left as it is. The test waits for SSH afterwards.
# @arg: $1 - the run folder.
# @arg: $2 - the log name, for example install-vm-start.
# @arg: $3 - the VM name.
# @stdout: NOTE started or already running, or the problem.
# @exitcode: 0 if it is running, 1 otherwise.
vm-start-if-stopped() {
    local run_dir name vm
    run_dir="${1}"
    name="${2}"
    vm="${3}"
    if [[ -n "${TST_RPM_INSTALLER_BASE:-}" && "${vm}" == "${TST_RPM_INSTALLER_BASE}" ]]; then
        echo "The base VM ${vm} must not be started this way"
        return 1
    fi
    if ! vm-exists "${vm}"; then
        write-log "${run_dir}" "${name}" "VM ${vm}: missing"
        echo "The VM ${vm} does not exist"
        echo "Fix: ./test install-vm-create"
        return 1
    fi
    if vm-running "${vm}"; then
        echo "NOTE: already running"
        return 0
    fi
    if ! vm-virsh start "${vm}" >/dev/null 2>&1; then
        write-log "${run_dir}" "${name}" "VM ${vm}: start failed"
        echo "The VM ${vm} could not be started"
        return 1
    fi
    write-log "${run_dir}" "${name}" "VM ${vm}: started"
    echo "NOTE: started"
}
