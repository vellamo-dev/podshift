#!/usr/bin/env bash
# @file: 130-images.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example images added.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Adds one example image of each source: Quadlet, container and unmanaged.
# @details:
#   Installs the .image and .container files into PODSHIFT_PODMAN_QUADLETS_DIR of the podshift
#   user, runs daemon-reload, starts the Quadlet image units (<base>-image.service) and the
#   container units (<base>.service), then pulls each image in unmanaged.list that does not exist
#   yet. Existing files are replaced and existing images are kept, so it can run again.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was added, or the problem.
# @exitcode: 0 if all were added, 1 on an error, 3 if the VM is not running.
images() {
    local run_dir vm dir file base ref count
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/images"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    count=0
    for file in "${dir}"/example-*.image "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        vm-podshift-install-file "${vm}" "${file}" /home/podshift/.config/containers/systemd || return 1
        count=$((count + 1))
    done
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    for file in "${dir}"/example-*.image; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}" .image)"
        if ! vm-podshift-systemctl "${vm}" start "${base}-image.service"; then
            write-log "${run_dir}" postinstall-examples "start ${base}-image.service failed"
            echo "Could not start ${base}-image.service"
            return 1
        fi
    done
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}" .container)"
        if ! vm-podshift-systemctl "${vm}" start "${base}.service"; then
            write-log "${run_dir}" postinstall-examples "start ${base}.service failed"
            echo "Could not start ${base}.service"
            return 1
        fi
    done
    while IFS= read -r ref; do
        [[ -n "${ref}" ]] || continue
        if vm-podshift-run "${vm}" podman image exists "${ref}"; then
            continue
        fi
        if ! vm-podshift-run "${vm}" podman pull --quiet "${ref}" >/dev/null; then
            write-log "${run_dir}" postinstall-examples "podman pull ${ref} failed"
            echo "Could not pull the image ${ref}"
            return 1
        fi
        count=$((count + 1))
    done <<< "$(example-image-lines "${dir}/unmanaged.list")"
    write-log "${run_dir}" postinstall-examples "example images in place, ${count} files or images added or replaced"
    echo "NOTE: example images in place"
    return 0
}
