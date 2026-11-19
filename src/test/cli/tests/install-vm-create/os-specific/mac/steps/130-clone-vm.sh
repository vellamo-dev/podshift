#!/usr/bin/env bash
# @file: 130-clone-vm.sh
# @source-dir: src/test/cli/tests/install-vm-create/os-specific/mac/steps
# @group: test
# @category: step
# @description: Clone RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Clones the RPM installer VM from the stopped Lima base VM TST_RPM_INSTALLER_BASE, without starting it.
# @details:
#   It sets the CPUs and memory (TST_RPM_INSTALLER_CPUS, TST_RPM_INSTALLER_MEMORY) and the MAC
#   address (TST_VM_MAC). If TST_DEV_SHARE exists, a read-only virtiofs mount is added on the
#   clone at TST_DEV_SHARE_MOUNT, using limactl clone --set, without changing the base image.
#   install-image builds the base, and install-vm-start boots the clone. The limactl output is
#   saved to lima-clone.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: NOTE with the CPUs and memory, and the end of the limactl output on failure.
# @exitcode: 0 if cloned, 1 otherwise.
clone-vm() {
    local run_dir base mem log share_note
    local -a clone_opts
    run_dir="${1}"
    base="${TST_RPM_INSTALLER_BASE}"
    log="${run_dir}/lima-clone.log"
    share_note=""
    case "${TST_RPM_INSTALLER_MEMORY}" in
        *G) mem="${TST_RPM_INSTALLER_MEMORY%G}" ;;
        *)  echo "TST_RPM_INSTALLER_MEMORY must end in G, for example 8G, not ${TST_RPM_INSTALLER_MEMORY}"; return 1 ;;
    esac
    if ! vm-exists "${base}" || vm-running "${base}"; then
        write-log "${run_dir}" install-vm-create "Base ${base}: missing or running"
        echo "The base VM ${base} is missing or running"
        echo "Fix: ./test install-image"
        return 1
    fi
    clone_opts=(
        --tty=false "${base}" "${TST_RPM_INSTALLER_VM}"
        --cpus "${TST_RPM_INSTALLER_CPUS}" --memory "${mem}"
        --set ".networks[0].macAddress = \"${TST_VM_MAC}\""
    )
    if [[ -n "${TST_DEV_SHARE}" && -d "${TST_DEV_SHARE}" ]]; then
        clone_opts+=(--set ".mounts += [{\"location\": \"${TST_DEV_SHARE}\", \"mountPoint\": \"${TST_DEV_SHARE_MOUNT}\", \"writable\": false}]")
        share_note=", share ${TST_DEV_SHARE} -> ${TST_DEV_SHARE_MOUNT}"
    fi
    if ! vm clone "${clone_opts[@]}" >"${log}" 2>&1; then
        write-log "${run_dir}" install-vm-create "VM ${TST_RPM_INSTALLER_VM}: limactl clone failed, see ${log}"
        tail -n 20 "${log}"
        echo "The VM ${TST_RPM_INSTALLER_VM} could not be cloned from ${base}, see ${log}"
        return 1
    fi
    write-log "${run_dir}" install-vm-create "VM ${TST_RPM_INSTALLER_VM}: cloned from ${base}, ${TST_RPM_INSTALLER_CPUS} CPUs, ${TST_RPM_INSTALLER_MEMORY}${share_note}"
    echo "NOTE: ${TST_RPM_INSTALLER_CPUS} CPUs, ${TST_RPM_INSTALLER_MEMORY}${share_note}"
}
