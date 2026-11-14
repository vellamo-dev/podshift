#!/usr/bin/env bash
# @file: 140-mount-cockpit-dev-share.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Mount the plugin share.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Mounts the cockpit-podshift dist share at TST_DEV_SHARE_MOUNT when that folder exists.
# @details:
#   On a Mac, Lima already mounts it at clone time. On Fedora, the step runs mount -t virtiofs
#   cockpit-podshift. If the host folder is missing, it prints a note and continues. If the
#   folder exists but the VM has no share, the VM needs to be created again.
# @arg: $1 - the run folder.
# @stdout: NOTE with the mount result, or the problem and how to fix it.
# @exitcode: 0 if the share is mounted or is not present, 3 if the VM should be recreated, 1 on a mount error.
mount-cockpit-dev-share() {
    local run_dir mount_point
    run_dir="${1}"
    mount_point="${TST_DEV_SHARE_MOUNT:-/mnt/cockpit-podshift}"
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin share: cockpit-podshift dist/ not found, skipped"
        echo "NOTE: cockpit-podshift dist/ not found, share not mounted"
        return 0
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${mount_point}"; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin share: already mounted at ${mount_point}"
        echo "NOTE: ${mount_point}"
        return 0
    fi
    if [[ -n "${TST_LIMA_CONFIG:-}" ]]; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin share: ${mount_point} is not mounted, recreate the VM"
        echo "The share was not mounted in the VM at ${mount_point}"
        echo "Fix: ./test install-vm-start"
        return 3
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" mkdir -p "${mount_point}"; then
        echo "Could not create ${mount_point} in the VM"
        return 1
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" mount -t virtiofs cockpit-podshift "${mount_point}"; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin share: mount -t virtiofs cockpit-podshift ${mount_point} failed"
        echo "Could not mount virtiofs cockpit-podshift at ${mount_point}"
        echo "Fix: ./test install-vm-start"
        return 3
    fi
    write-log "${run_dir}" postinstall-ui-dev-mount "plugin share: mounted virtiofs at ${mount_point}"
    echo "NOTE: ${mount_point}"
}
