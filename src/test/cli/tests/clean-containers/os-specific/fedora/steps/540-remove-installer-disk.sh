#!/usr/bin/env bash
# @file: 540-remove-installer-disk.sh
# @source-dir: src/test/cli/tests/clean-containers/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Remove RPM installer VM disk.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the built RPM installer VM disk in TST_VM_IMAGE_DIR and any unfinished .part files.
# @details:
#   The downloaded Fedora Server image is kept, like the Fedora base image on the Mac, so it is not
#   downloaded again.
# @arg: $1 - the run folder.
# @stdout: NOTE with how many files were removed, or none found.
# @exitcode: 0 if none are left, 1 otherwise.
remove-installer-disk() {
    local run_dir disk files
    run_dir="${1}"
    disk="${TST_VM_IMAGE_DIR}/${TST_RPM_INSTALLER_IMG}-${TST_FEDORA_VERSION}.qcow2"
    files=()
    [[ ! -e "${disk}" ]] || files+=("${disk}")
    [[ ! -e "${disk}.part" ]] || files+=("${disk}.part")
    [[ ! -e "${TST_VM_IMAGE_DIR}/${TST_FEDORA_IMAGE_URL##*/}.part" ]] || files+=("${TST_VM_IMAGE_DIR}/${TST_FEDORA_IMAGE_URL##*/}.part")
    if (( ${#files[@]} == 0 )); then
        echo "NOTE: none found"
        return 0
    fi
    rm -f "${files[@]}" || { echo "Files in ${TST_VM_IMAGE_DIR} could not be removed"; return 1; }
    write-log "${run_dir}" clean-containers "Removed ${files[*]}"
    echo "NOTE: ${#files[@]} removed"
}
