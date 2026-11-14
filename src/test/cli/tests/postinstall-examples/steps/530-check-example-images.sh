#!/usr/bin/env bash
# @file: 530-check-example-images.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example images present.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every example image and example container exists for the podshift user.
# @details:
#   The expected images are the Image= of each example .image and .container file and each line
#   of unmanaged.list. The expected containers are the ContainerName= of each example .container
#   file.
# @arg: $1 - the run folder.
# @stdout: NOTE with the number of images, or the missing ones.
# @exitcode: 0 if all exist, 2 if any is missing, 3 if the VM is not running.
check-example-images() {
    local run_dir vm dir file ref name count
    local -a missing
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/images"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    missing=()
    count=0
    while IFS= read -r ref; do
        [[ -n "${ref}" ]] || continue
        count=$((count + 1))
        vm-podshift-run "${vm}" podman image exists "${ref}" || missing+=("${ref}")
    done <<< "$(example-image-refs "${dir}")"
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        name="$(sed -n 's/^ContainerName=//p' "${file}" | tail -n 1)"
        name="${name:-systemd-$(basename "${file}" .container)}"
        vm-podshift-run "${vm}" podman container exists "${name}" || missing+=("container ${name}")
    done
    if [[ "${#missing[@]}" -gt 0 ]]; then
        write-log "${run_dir}" postinstall-examples "missing images: ${missing[*]}"
        echo "Missing: ${missing[*]}"
        echo "Fix: ./test postinstall-examples"
        return 2
    fi
    write-log "${run_dir}" postinstall-examples "${count} example images exist"
    echo "NOTE: ${count} example images exist"
    return 0
}
