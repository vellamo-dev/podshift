#!/usr/bin/env bash
# @file: 510-verify-installer-disk.sh
# @source-dir: src/test/cli/tests/install-image/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM disk.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM installer VM disk exists and that qemu-img finds no errors in it.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if the disk is fine, 1 otherwise.
verify-installer-disk() {
    local run_dir disk
    run_dir="${1}"
    disk="${TST_VM_IMAGE_DIR}/${TST_RPM_INSTALLER_IMG}-${TST_FEDORA_VERSION}.qcow2"
    if [[ ! -f "${disk}" ]]; then
        write-log "${run_dir}" install-image "Disk ${disk}: missing"
        echo "The disk ${disk} does not exist"
        return 1
    fi
    if ! qemu-img check -q "${disk}"; then
        write-log "${run_dir}" install-image "Disk ${disk}: qemu-img check failed"
        echo "qemu-img found errors in ${disk}"
        return 1
    fi
    write-log "${run_dir}" install-image "Disk ${disk}: present, qemu-img check ok"
}
