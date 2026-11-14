#!/usr/bin/env bash
# @file: 150-copy-ui-rpm-to-vm.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Copy cockpit-podshift RPM into VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies the newest local cockpit-podshift RPM into the VM's RPM folder with vm-copy, which uses scp.
# @details:
#   Old cockpit-podshift RPMs in that folder are removed first. The copy is checked by checksum.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file name or skipped, or the problem.
# @exitcode: 0 if copied or skipped, 1 otherwise.
copy-ui-rpm-to-vm() {
    local run_dir file out host_sum vm_sum
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    file="$(find-ui-rpm 2>&1)" || { echo "${file}"; return 1; }
    if ! out="$(vm-run "${TST_RPM_INSTALLER_VM}" find "${TST_RPM_INSTALLER_RPM_DIR}" -maxdepth 1 -name 'cockpit-podshift-*.rpm' -print -delete 2>&1)"; then
        echo "${out}"
        echo "Old cockpit-podshift RPMs in ${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR} could not be removed"
        return 1
    fi
    write-log "${run_dir}" postinstall-ui-install "Old cockpit-podshift RPMs in VM: $(printf '%s' "${out}" | grep -c .) removed"
    if ! vm-copy "${TST_RPM_INSTALLER_VM}" "${file}" "${TST_RPM_INSTALLER_RPM_DIR}"; then
        write-log "${run_dir}" postinstall-ui-install "Copy ${file##*/}: failed"
        echo "${file##*/} could not be copied into ${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR}"
        return 1
    fi
    host_sum="$(cksum <"${file}")"
    vm_sum="$(vm-run "${TST_RPM_INSTALLER_VM}" cksum "${TST_RPM_INSTALLER_RPM_DIR}/${file##*/}" 2>/dev/null | awk '{ print $1, $2 }')"
    if [[ -z "${vm_sum}" || "${host_sum}" != "${vm_sum}" ]]; then
        write-log "${run_dir}" postinstall-ui-install "Check RPM in VM matches the local one: failed"
        echo "${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR}/${file##*/} is not the same as ${file}"
        return 1
    fi
    write-log "${run_dir}" postinstall-ui-install "Copy ${file##*/}: to ${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR}, checksum ok"
    echo "NOTE: ${file##*/}"
}
