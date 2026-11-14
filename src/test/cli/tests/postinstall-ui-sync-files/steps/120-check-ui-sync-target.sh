#!/usr/bin/env bash
# @file: 120-check-ui-sync-target.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files/steps
# @group: test
# @category: step
# @description: Check the installed UI or a dev mount.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the UI is installed in the VM, or skips when a dev mount is already in use.
# @details:
#   If /usr/share/cockpit/podshift or /usr/local/share/cockpit/podshift is a mount point, it prints
#   that the dev mount is in use and nothing will be synced. If cockpit-podshift is not installed,
#   it fails. When the dist is missing, it skips.
# @arg: $1 - the run folder.
# @stdout: NOTE with the target, the mount, or skipped, or the problem and how to fix it.
# @exitcode: 0 if ready, skipped or the dev mount is in use, 3 if the UI is missing or the VM is not running.
check-ui-sync-target() {
    local run_dir dest local_dest
    run_dir="${1}"
    dest=/usr/share/cockpit/podshift
    local_dest=/usr/local/share/cockpit/podshift
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        echo "NOTE: skipped"
        return 0
    fi
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${dest}" \
        || vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${local_dest}"; then
        write-log "${run_dir}" postinstall-ui-sync-files "dev mount in use, nothing to sync"
        echo "NOTE: dev mount in use, nothing to sync"
        return 0
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" test -f "${dest}/manifest.json"; then
        write-log "${run_dir}" postinstall-ui-sync-files "${dest}/manifest.json: missing"
        echo "cockpit-podshift is not installed in ${TST_RPM_INSTALLER_VM} (${dest}/manifest.json is missing)"
        echo "Fix: ./test postinstall-ui-install"
        return 3
    fi
    write-log "${run_dir}" postinstall-ui-sync-files "sync target: ${dest}"
    echo "NOTE: ${dest}"
}
