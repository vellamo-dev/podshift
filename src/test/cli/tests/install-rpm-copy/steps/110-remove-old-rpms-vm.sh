#!/usr/bin/env bash
# @file: 110-remove-old-rpms-vm.sh
# @source-dir: src/test/cli/tests/install-rpm-copy/steps
# @group: test
# @category: step
# @description: Remove old RPMs in VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes any PodShift RPMs left in the VM's RPM folder.
# @arg: $1 - the run folder.
# @stdout: NOTE none found or removed N.
# @exitcode: 0 if done, 1 if the VM does not answer.
remove-old-rpms-vm() {
    local run_dir out count
    run_dir="${1}"
    if ! out="$(vm-run "${TST_RPM_INSTALLER_VM}" find "${TST_RPM_INSTALLER_RPM_DIR}" -maxdepth 1 -name 'podshift-*.rpm' -print -delete 2>&1)"; then
        echo "${out}"
        echo "Old RPMs in ${TST_RPM_INSTALLER_VM}:${TST_RPM_INSTALLER_RPM_DIR} could not be removed"
        return 1
    fi
    count="$(printf '%s' "${out}" | grep -c .)"
    write-log "${run_dir}" install-rpm-copy "Old RPMs in VM: ${count} removed"
    if (( count == 0 )); then
        echo "NOTE: none found"
    else
        echo "NOTE: removed ${count}"
    fi
}
