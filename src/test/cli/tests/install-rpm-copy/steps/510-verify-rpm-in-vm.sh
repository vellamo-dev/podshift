#!/usr/bin/env bash
# @file: 510-verify-rpm-in-vm.sh
# @source-dir: src/test/cli/tests/install-rpm-copy/steps
# @group: test
# @category: step
# @description: Verify RPM in VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM in the VM is the same as the exported one, by checksum and size.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if the same, 1 otherwise.
verify-rpm-in-vm() {
    local run_dir file host_sum vm_sum
    run_dir="${1}"
    file="$(find-exported-rpm "${TST_RPM_SHARE_DIR}" 2>&1)" || { echo "${file}"; return 1; }
    host_sum="$(cksum <"${file}")"
    vm_sum="$(vm-run "${TST_RPM_INSTALLER_VM}" cksum "${TST_RPM_INSTALLER_RPM_DIR}/${file##*/}" 2>/dev/null | awk '{ print $1, $2 }')"
    if [[ -z "${vm_sum}" || "${host_sum}" != "${vm_sum}" ]]; then
        write-log "${run_dir}" install-rpm-copy "Check RPM in VM matches the exported one: failed"
        echo "${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR}/${file##*/} is missing or not the same as ${file}"
        return 1
    fi
    write-log "${run_dir}" install-rpm-copy "Check RPM in VM matches the exported one: ok"
}
