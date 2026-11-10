#!/usr/bin/env bash
# @file: 530-remove-images.sh
# @source-dir: src/test/cli/tests/clean-containers/steps
# @group: test
# @category: step
# @description: Remove RPM builder and installer images.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes every tag of the RPM builder and installer images, after the VM and container are gone.
# @arg: $1 - the run folder.
# @stdout: NOTE with how many were removed, and a DETAIL line for each image that could not be removed.
# @exitcode: 0 if all are removed, 1 otherwise.
remove-images() {
    local run_dir name image removed failed
    run_dir="${1}"
    removed=0
    failed=0
    for name in "${TST_RPM_BUILDER_IMG}" "${TST_RPM_INSTALLER_IMG}"; do
        for image in $(image-tags "${name}"); do
            if container-cli image rm "${image}" >/dev/null 2>&1; then
                write-log "${run_dir}" clean-containers "Image ${image}: removed"
                removed=$((removed + 1))
            else
                echo "DETAIL: ${image} could not be removed"
                failed=$((failed + 1))
            fi
        done
    done
    if (( failed > 0 )); then
        echo "NOTE: ${removed} removed, ${failed} could not be removed"
        return 1
    fi
    if (( removed == 0 )); then
        echo "NOTE: none found"
        return 0
    fi
    echo "NOTE: ${removed} removed"
}
