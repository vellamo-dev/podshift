#!/usr/bin/env bash
# @file: 130-sync-ui-files.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files/steps
# @group: test
# @category: step
# @description: Copy dist over the installed UI.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies dist/ into a temporary folder on the VM and syncs it into the installed UI.
# @details:
#   The dist is packed on the host and copied with vm-copy. On the VM, rsync -a --delete is used
#   when rsync is present, otherwise the target contents are cleared and copied. Files are left
#   owned by root, restorecon -R is run when it is present, and the temporary folder is removed.
# @arg: $1 - the run folder.
# @stdout: NOTE with how it was synced or skipped, or the problem.
# @exitcode: 0 if synced or skipped, 1 otherwise.
sync-ui-files() {
    local run_dir dest vm_tmp host_tmp src_tar method
    run_dir="${1}"
    dest=/usr/share/cockpit/podshift
    vm_tmp=/tmp/podshift-ui-sync
    host_tmp="artifacts/work/postinstall-ui-sync-files"
    src_tar="${host_tmp}/ui-dist.tar"
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        echo "NOTE: skipped"
        return 0
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${dest}" \
        || vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q /usr/local/share/cockpit/podshift; then
        echo "NOTE: skipped"
        return 0
    fi
    mkdir -p "${host_tmp}" || { echo "The folder ${host_tmp} could not be created"; return 1; }
    rm -f "${src_tar}"
    # COPYFILE_DISABLE keeps macOS ._ files out of the tar.
    if ! COPYFILE_DISABLE=1 tar --no-xattrs -C "${TST_DEV_SHARE}" \
        --exclude=.DS_Store --exclude='._*' \
        -cf "${src_tar}" .; then
        echo "The UI dist could not be packed"
        return 1
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" \
        || ! vm-run "${TST_RPM_INSTALLER_VM}" mkdir -p "${vm_tmp}/dist"; then
        rm -f "${src_tar}"
        echo "The temporary folder ${vm_tmp} could not be created in the VM"
        return 1
    fi
    if ! vm-copy "${TST_RPM_INSTALLER_VM}" "${src_tar}" "${vm_tmp}"; then
        vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
        rm -f "${src_tar}"
        echo "The UI dist could not be copied into ${TST_RPM_INSTALLER_VM}:${vm_tmp}"
        return 1
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" tar --no-same-owner -C "${vm_tmp}/dist" -xf "${vm_tmp}/ui-dist.tar"; then
        vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
        rm -f "${src_tar}"
        echo "The UI dist could not be unpacked in the VM"
        return 1
    fi
    rm -f "${src_tar}"
    if vm-run "${TST_RPM_INSTALLER_VM}" command -v rsync >/dev/null; then
        if ! vm-run "${TST_RPM_INSTALLER_VM}" rsync -a --delete "${vm_tmp}/dist/" "${dest}/"; then
            vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
            echo "rsync could not update ${dest}"
            return 1
        fi
        method=rsync
    else
        if ! vm-run "${TST_RPM_INSTALLER_VM}" find "${dest}" -mindepth 1 -delete \
            || ! vm-run "${TST_RPM_INSTALLER_VM}" cp -a "${vm_tmp}/dist/." "${dest}/"; then
            vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
            echo "The UI files could not be copied into ${dest}"
            return 1
        fi
        method=cp
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" chown -R root:root "${dest}"; then
        vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
        echo "Could not set root ownership on ${dest}"
        return 1
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" command -v restorecon >/dev/null; then
        if ! vm-run "${TST_RPM_INSTALLER_VM}" restorecon -R "${dest}"; then
            vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
            echo "restorecon -R ${dest} failed"
            return 1
        fi
    fi
    vm-run "${TST_RPM_INSTALLER_VM}" rm -rf "${vm_tmp}" || true
    write-log "${run_dir}" postinstall-ui-sync-files "synced ${TST_DEV_SHARE} to ${dest} with ${method}"
    echo "NOTE: ${dest} (${method})"
}
