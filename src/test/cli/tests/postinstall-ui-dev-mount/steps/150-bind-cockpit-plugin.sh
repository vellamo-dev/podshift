#!/usr/bin/env bash
# @file: 150-bind-cockpit-plugin.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Bind-mount the plugin for all users.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Bind-mounts the plugin share read-only into /usr/local/share/cockpit/podshift.
# @details:
#   Cockpit builds its menu from the login user's home and the system folders, also with
#   administrative access on, so the plugin goes into a system folder that every login sees.
#   Old binds in the root and podshift home folders, from earlier runs, are removed first.
#   If the share is not mounted, the step prints a note and continues.
# @arg: $1 - the run folder.
# @stdout: NOTE with the bind folder, or that the share is absent.
# @exitcode: 0 if the bind is in place or the share is absent, 1 if the bind failed.
bind-cockpit-plugin() {
    local run_dir mount_point dest old
    run_dir="${1}"
    mount_point="${TST_DEV_SHARE_MOUNT:-/mnt/cockpit-podshift}"
    dest=/usr/local/share/cockpit/podshift
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]] \
        || ! vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${mount_point}"; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin bind: share not mounted, skipped"
        echo "NOTE: plugin share not mounted, skipped"
        return 0
    fi
    for old in /root/.local/share/cockpit/podshift /home/podshift/.local/share/cockpit/podshift; do
        if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${old}"; then
            if ! vm-run "${TST_RPM_INSTALLER_VM}" umount "${old}"; then
                echo "Could not remove the old bind at ${old}"
                return 1
            fi
            write-log "${run_dir}" postinstall-ui-dev-mount "plugin bind: removed old ${old}"
        fi
    done
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${dest}"; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin bind: ${dest} already in place"
        echo "NOTE: ${dest}"
        return 0
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" mkdir -p "${dest}"; then
        echo "Could not create ${dest} in the VM"
        return 1
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" mount --bind "${mount_point}" "${dest}" \
        || ! vm-run "${TST_RPM_INSTALLER_VM}" mount -o remount,bind,ro "${dest}"; then
        write-log "${run_dir}" postinstall-ui-dev-mount "plugin bind: failed for ${dest}"
        echo "Could not bind-mount ${mount_point} to ${dest} read-only"
        return 1
    fi
    write-log "${run_dir}" postinstall-ui-dev-mount "plugin bind: ${dest}"
    echo "NOTE: ${dest}"
}
