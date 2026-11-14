#!/usr/bin/env bash
# @file: 130-create-libvirt-vm.sh
# @source-dir: src/test/cli/tests/install-vm-start/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Create RPM installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Uploads a fresh copy of the RPM installer VM disk to the libvirt pool, then creates and boots the VM.
# @details:
#   The copy is needed because libvirt cannot read files in the home folder. virt-install creates
#   the VM and also boots it. If TST_DEV_SHARE exists, a read-only virtiofs filesystem is added
#   (target cockpit-podshift) with shared memory backing. That share still lives on the host path,
#   often under the home folder, so SELinux or qemu access may need extra rules.
# @arg: $1 - the run folder.
# @stdout: NOTE with the CPUs and memory, and the virt-install output on failure.
# @exitcode: 0 if created and started, 1 otherwise.
create-libvirt-vm() {
    local run_dir disk vol size mem_mib share_note
    local -a vi_opts
    run_dir="${1}"
    disk="${TST_VM_IMAGE_DIR}/${TST_RPM_INSTALLER_IMG}-${TST_FEDORA_VERSION}.qcow2"
    vol="${TST_RPM_INSTALLER_VM}.qcow2"
    share_note=""
    case "${TST_RPM_INSTALLER_MEMORY}" in
        *G) mem_mib=$(( ${TST_RPM_INSTALLER_MEMORY%G} * 1024 )) ;;
        *M) mem_mib="${TST_RPM_INSTALLER_MEMORY%M}" ;;
        *)  echo "TST_RPM_INSTALLER_MEMORY must end in G or M, for example 8G, not ${TST_RPM_INSTALLER_MEMORY}"; return 1 ;;
    esac
    if [[ ! -f "${disk}" ]]; then
        write-log "${run_dir}" install-vm-start "Disk ${disk}: missing"
        echo "The disk ${disk} does not exist. install-image builds it."
        return 1
    fi
    size="$(qemu-img info --output=json "${disk}" | awk -F '[:,]' '/"virtual-size"/ { gsub(/ /, "", $2); print $2; exit }')"
    if ! vm-virsh vol-create-as --pool "${TST_VM_POOL}" --name "${vol}" --capacity "${size}" --format qcow2 >/dev/null \
        || ! vm-virsh vol-upload --pool "${TST_VM_POOL}" --vol "${vol}" --file "${disk}" --sparse >/dev/null; then
        write-log "${run_dir}" install-vm-start "Disk ${TST_VM_POOL}/${vol}: upload of ${disk} failed"
        echo "The disk could not be uploaded to the libvirt pool ${TST_VM_POOL}"
        return 1
    fi
    vi_opts=(
        --connect qemu:///system --name "${TST_RPM_INSTALLER_VM}"
        --vcpus "${TST_RPM_INSTALLER_CPUS}" --memory "${mem_mib}"
        --import --disk "vol=${TST_VM_POOL}/${vol},format=qcow2,bus=virtio"
        --network network=default --osinfo detect=on,require=off
        --graphics none --noautoconsole
    )
    if [[ -n "${TST_DEV_SHARE}" && -d "${TST_DEV_SHARE}" ]]; then
        vi_opts+=(
            --filesystem "source=${TST_DEV_SHARE},target=cockpit-podshift,driver.type=virtiofs,readonly=yes"
            --memorybacking source.type=memfd,access.mode=shared
        )
        share_note=", share ${TST_DEV_SHARE} -> ${TST_DEV_SHARE_MOUNT}"
    fi
    if ! virt-install "${vi_opts[@]}" </dev/null; then
        write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: virt-install failed"
        echo "The VM ${TST_RPM_INSTALLER_VM} could not be created"
        return 1
    fi
    write-log "${run_dir}" install-vm-start "VM ${TST_RPM_INSTALLER_VM}: created from ${disk}, ${TST_RPM_INSTALLER_CPUS} CPUs, ${TST_RPM_INSTALLER_MEMORY}${share_note}"
    echo "NOTE: ${TST_RPM_INSTALLER_CPUS} CPUs, ${TST_RPM_INSTALLER_MEMORY}${share_note}"
}
