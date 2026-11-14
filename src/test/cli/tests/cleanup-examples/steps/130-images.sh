#!/usr/bin/env bash
# @file: 130-images.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: Example images removed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the example image and container units, removes their files, then removes the example images.
# @details:
#   Units and files are taken from the example-*.image and example-*.container fixture names, so
#   no other file is touched. Stopping a Quadlet container also removes it. Images are removed
#   only when their reference is used by an example file or listed in unmanaged.list. Images are
#   removed without --force, so an image still used by another container is reported and kept.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or the problem.
# @exitcode: 0 if all were removed or kept on purpose, 1 on an error, 3 if the VM is not running.
images() {
    local run_dir vm dir file base ref removed
    local -a kept
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/images"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-podshift-systemctl "${vm}" stop "${base%.container}.service" >/dev/null 2>&1 || true
        vm-run "${vm}" rm -f "/home/podshift/.config/containers/systemd/${base}" || { echo "Could not remove ${base}"; return 1; }
    done
    for file in "${dir}"/example-*.image; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-podshift-systemctl "${vm}" stop "${base%.image}-image.service" >/dev/null 2>&1 || true
        vm-run "${vm}" rm -f "/home/podshift/.config/containers/systemd/${base}" || { echo "Could not remove ${base}"; return 1; }
    done
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    vm-podshift-systemctl "${vm}" reset-failed >/dev/null 2>&1 || true
    removed=0
    kept=()
    while IFS= read -r ref; do
        [[ -n "${ref}" ]] || continue
        vm-podshift-run "${vm}" podman image exists "${ref}" || continue
        if vm-podshift-run "${vm}" podman image rm "${ref}" >/dev/null 2>&1; then
            removed=$((removed + 1))
        else
            kept+=("${ref}")
        fi
    done <<< "$(example-image-refs "${dir}")"
    if [[ "${#kept[@]}" -gt 0 ]]; then
        write-log "${run_dir}" cleanup-examples "images kept, still in use: ${kept[*]}"
        echo "NOTE: kept images still used by a container: ${kept[*]}"
    fi
    write-log "${run_dir}" cleanup-examples "example image files removed, ${removed} images removed"
    echo "NOTE: ${removed} example images removed"
    return 0
}
