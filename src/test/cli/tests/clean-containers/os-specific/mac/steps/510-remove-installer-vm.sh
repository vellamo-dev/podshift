#!/usr/bin/env bash
# @file: 510-remove-installer-vm.sh
# @source-dir: src/test/cli/tests/clean-containers/os-specific/mac/steps
# @group: test
# @category: step
# @description: Remove RPM installer VM and its base.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops and removes the RPM installer VM and the Lima base VM it is cloned from (TST_RPM_INSTALLER_BASE), if they exist.
# @details:
#   A running VM is powered off at once, because Lima's normal stop needs SSH on port 22, which
#   PodShift closes.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or none found.
# @exitcode: 0 if neither exists anymore, 1 otherwise.
remove-installer-vm() {
    local run_dir name removed
    run_dir="${1}"
    removed=""
    for name in "${TST_RPM_INSTALLER_VM}" "${TST_RPM_INSTALLER_BASE}"; do
        vm-exists "${name}" || continue
        if vm-running "${name}"; then
            vm stop -f "${name}" >/dev/null 2>&1 || { echo "The VM ${name} could not be stopped"; return 1; }
        fi
        vm delete -f "${name}" >/dev/null 2>&1 || { echo "The VM ${name} could not be removed"; return 1; }
        write-log "${run_dir}" clean-containers "VM ${name}: removed"
        removed="${removed:+${removed}, }${name}"
    done
    echo "NOTE: ${removed:-none found}${removed:+ removed}"
}
