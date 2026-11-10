#!/usr/bin/env bash
# @file: 130-clone-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/mac/steps
# @group: test
# @category: step
# @description: Clone RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Clones the RPM installer VM from the stopped Lima base VM TST_RPM_INSTALLER_BASE (see install-image) and boots it.
# @details:
#   It sets the CPUs and memory (TST_RPM_INSTALLER_CPUS, TST_RPM_INSTALLER_MEMORY) and the MAC
#   address (TST_VM_MAC). At boot the clone runs the config's provision script again, which only
#   updates packages that are newer than the base. It returns once that has finished, up to
#   TST_LIMA_START_TIMEOUT. The limactl output is saved to lima-start.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: NOTE with the CPUs and memory, and the end of the limactl output on failure.
# @exitcode: 0 if cloned and started, 1 otherwise.
clone-vm() {
    local run_dir base mem log
    run_dir="${1}"
    base="${TST_RPM_INSTALLER_BASE}"
    log="${run_dir}/lima-start.log"
    case "${TST_RPM_INSTALLER_MEMORY}" in
        *G) mem="${TST_RPM_INSTALLER_MEMORY%G}" ;;
        *)  echo "TST_RPM_INSTALLER_MEMORY must end in G, for example 8G, not ${TST_RPM_INSTALLER_MEMORY}"; return 1 ;;
    esac
    if ! vm-exists "${base}" || vm-running "${base}"; then
        write-log "${run_dir}" install-vm-start "Base ${base}: missing or running"
        echo "The base VM ${base} is missing or running"
        echo "Fix: ./test install-image"
        return 1
    fi
    if ! vm clone --tty=false "${base}" "${TST_RPM_INSTALLER_VM}" \
        --cpus "${TST_RPM_INSTALLER_CPUS}" --memory "${mem}" \
        --set ".networks[0].macAddress = \"${TST_VM_MAC}\"" >"${log}" 2>&1; then
        write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: limactl clone failed, see ${log}"
        tail -n 20 "${log}"
        echo "The VM ${TST_RPM_INSTALLER_VM} could not be cloned from ${base}, see ${log}"
        return 1
    fi
    if ! vm start --tty=false --timeout "${TST_LIMA_START_TIMEOUT}" "${TST_RPM_INSTALLER_VM}" >>"${log}" 2>&1; then
        write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: limactl start failed, see ${log}"
        tail -n 20 "${log}"
        echo "The VM ${TST_RPM_INSTALLER_VM} could not be started, see ${log}"
        return 1
    fi
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: cloned from ${base}, ${TST_RPM_INSTALLER_CPUS} CPUs, ${TST_RPM_INSTALLER_MEMORY}"
    echo "NOTE: ${TST_RPM_INSTALLER_CPUS} CPUs, ${TST_RPM_INSTALLER_MEMORY}"
}
