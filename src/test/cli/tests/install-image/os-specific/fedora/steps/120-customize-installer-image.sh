#!/usr/bin/env bash
# @file: 120-customize-installer-image.sh
# @source-dir: src/test/cli/tests/install-image/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Build RPM installer VM disk.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Builds the RPM installer VM disk from the Fedora Server image with virt-customize, or reuses it if it is new enough.
# @details:
#   It gets the same packages and settings as the Lima config on the Mac
#   (src/test/cli/os-specific/mac/lima/rpm-installer.yaml), and the test VM SSH key for root. Root
#   is first grown into the free space of its LVM volume group, because the image's 3.2 GB root is
#   too small for the upgrade. The first-boot wizard (initial-setup) is turned off, since it waits
#   for input on the console, and systemd-repart is masked, since root is already grown.
# @arg: $1 - the run folder.
# @stdout: NOTE with what happened and why, and the virt-customize output.
# @exitcode: 0 if the disk is ready, 1 otherwise.
customize-installer-image() {
    local run_dir base disk key age shown reason
    run_dir="${1}"
    base="${TST_VM_IMAGE_DIR}/${TST_FEDORA_IMAGE_URL##*/}"
    disk="${TST_VM_IMAGE_DIR}/${TST_RPM_INSTALLER_IMG}-${TST_FEDORA_VERSION}.qcow2"
    key="${HOME}/.ssh/podshift-test-vm.pub"
    age="$(file-age "${disk}")"
    shown=""
    [[ -z "${age}" ]] || shown="$(format-age "${age}")"
    reason=""
    [[ "${TST_RPM_INSTALLER_REUSE}" == "true" ]] || reason="reuse off"
    [[ -n "${reason}" || -n "${age}" ]] || reason="no disk"
    [[ -n "${reason}" || ! "${base}" -nt "${disk}" ]] || reason="new base image"
    [[ -n "${reason}" || "${age}" -lt $(( TST_RPM_INSTALLER_MAX_AGE_HOURS * 3600 )) ]] \
        || reason="${shown} old, max ${TST_RPM_INSTALLER_MAX_AGE_HOURS}h"
    if [[ -z "${reason}" ]]; then
        write-log "${run_dir}" install-image "Disk ${disk}: reused, ${shown} old, max ${TST_RPM_INSTALLER_MAX_AGE_HOURS}h"
        echo "NOTE: reused, ${shown} old"
        return 0
    fi
    if [[ ! -f "${key}" ]]; then
        write-log "${run_dir}" install-image "Disk ${disk}: SSH key ${key} missing"
        echo "The test VM SSH key ${key} is missing"
        return 1
    fi
    rm -f "${disk}.part"
    if ! cp --sparse=always "${base}" "${disk}.part" || ! LIBGUESTFS_BACKEND=direct virt-customize -a "${disk}.part" \
        --run-command 'lvextend -r -l +100%FREE /dev/systemVG/LVRoot' \
        --update \
        --install systemd,systemd-udev,dbus,dbus-broker,NetworkManager,firewalld,openssh-server,cockpit,cockpit-ws,cockpit-system,selinux-policy-targeted,policycoreutils,tuned,chrony,rsyslog,dnf-plugins-core,net-tools,iproute,iputils,hostname,curl,wget,vim,sudo,procps-ng \
        --run-command 'systemctl enable sshd firewalld cockpit.socket chronyd NetworkManager tuned rsyslog' \
        --run-command 'systemctl set-default multi-user.target' \
        --run-command 'systemctl disable initial-setup.service || true' \
        --run-command 'systemctl mask systemd-repart.service' \
        --hostname fedora-server \
        --run-command 'firewall-offline-cmd --set-default-zone=public || true' \
        --run-command 'firewall-offline-cmd --add-service=ssh || true' \
        --run-command 'firewall-offline-cmd --add-service=cockpit || true' \
        --run-command "sed -i 's/^pool .*/pool 2.fedora.pool.ntp.org iburst/' /etc/chrony.conf" \
        --write /etc/tuned/active_profile:virtual-guest \
        --run-command "sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config" \
        --ssh-inject "root:file:${key}" \
        --selinux-relabel; then
        rm -f "${disk}.part"
        write-log "${run_dir}" install-image "Disk ${disk}: build failed (${reason})"
        echo "The disk ${disk} could not be built"
        return 1
    fi
    mv -f "${disk}.part" "${disk}"
    write-log "${run_dir}" install-image "Disk ${disk}: built, ${reason}, from ${base}"
    echo "NOTE: built, ${reason}"
}
