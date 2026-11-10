#!/usr/bin/env bash
# @file: 120-copy-rpm-to-vm.sh
# @source-dir: src/test/cli/tests/install-rpm-copy/steps
# @group: test
# @category: step
# @description: Copy RPM into VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies the exported RPM into the VM's RPM folder with vm-copy, which uses scp.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file name.
# @exitcode: 0 if copied, 1 otherwise.
copy-rpm-to-vm() {
    local run_dir file
    run_dir="${1}"
    file="$(find-exported-rpm "${TST_RPM_SHARE_DIR}" 2>&1)" || { echo "${file}"; return 1; }
    if ! vm-copy "${TST_RPM_INSTALLER_VM}" "${file}" "${TST_RPM_INSTALLER_RPM_DIR}"; then
        write-log "${run_dir}" install-rpm-copy "Copy ${file##*/}: failed"
        echo "${file##*/} could not be copied into ${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR}"
        return 1
    fi
    write-log "${run_dir}" install-rpm-copy "Copy ${file##*/}: to ${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR}"
    echo "NOTE: ${file##*/}"
}
