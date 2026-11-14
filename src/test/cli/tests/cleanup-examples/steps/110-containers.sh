#!/usr/bin/env bash
# @file: 110-containers.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: Example containers removed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the example container units, removes their files, then removes the example containers by name.
# @details:
#   Runs first, before the volume, image and secret cleanups, so no example container holds the
#   alpine image or an example secret. This includes example-secret-quadlet and example-secret-stopped.
#   Units and files are taken from the example-*.container and example-*.service fixture names, so
#   no other file is touched. The containers are the names from example-container-lines, all
#   starting with example-; each is removed with podman rm --force only when it exists.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or the problem.
# @exitcode: 0 if all were removed, 1 on an error, 3 if the VM is not running.
containers() {
    local run_dir vm dir file base line name removed
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/containers"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    for file in "${dir}"/example-*.service; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-podshift-systemctl "${vm}" disable --now "${base}" >/dev/null 2>&1 || true
        vm-run "${vm}" rm -f "/home/podshift/.config/systemd/user/${base}" || { echo "Could not remove ${base}"; return 1; }
    done
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-podshift-systemctl "${vm}" stop "${base%.container}.service" >/dev/null 2>&1 || true
        vm-run "${vm}" rm -f "/home/podshift/.config/containers/systemd/${base}" || { echo "Could not remove ${base}"; return 1; }
    done
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    vm-podshift-systemctl "${vm}" reset-failed >/dev/null 2>&1 || true
    removed=0
    while IFS= read -r line; do
        name="${line%% *}"
        [[ "${name}" == example-* ]] || continue
        vm-podshift-run "${vm}" podman container exists "${name}" || continue
        if ! vm-podshift-run "${vm}" podman rm --force --time 0 "${name}" >/dev/null; then
            write-log "${run_dir}" cleanup-examples "podman rm ${name} failed"
            echo "Could not remove the container ${name}"
            return 1
        fi
        removed=$((removed + 1))
    done <<< "$(example-container-lines "${dir}")"
    write-log "${run_dir}" cleanup-examples "example container files removed, ${removed} containers removed"
    echo "NOTE: ${removed} example containers removed"
    return 0
}
