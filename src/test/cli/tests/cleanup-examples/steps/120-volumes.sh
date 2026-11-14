#!/usr/bin/env bash
# @file: 120-volumes.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: Example volumes removed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the example volume units and containers, removes their files, then removes the example volumes.
# @details:
#   Runs before the image cleanup, so the example container no longer holds the alpine image.
#   Units and files are taken from the example-*.volume and example-*.container fixture names, so
#   no other file is touched. Stopping a Quadlet container also removes it. Volumes are removed
#   only when the name starts with example- and the volume has the podshift.example=1 label.
#   Volumes are removed without --force, so a volume still used by a container is reported and kept.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or the problem.
# @exitcode: 0 if all were removed, 1 on an error, 3 if the VM is not running.
volumes() {
    local run_dir vm dir file base name labeled removed
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/volumes"
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
    for file in "${dir}"/example-*.volume; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-podshift-systemctl "${vm}" stop "${base%.volume}-volume.service" >/dev/null 2>&1 || true
        vm-run "${vm}" rm -f "/home/podshift/.config/containers/systemd/${base}" || { echo "Could not remove ${base}"; return 1; }
    done
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    vm-podshift-systemctl "${vm}" reset-failed >/dev/null 2>&1 || true
    labeled="$(vm-podshift-run "${vm}" podman volume ls --filter label=podshift.example=1 --format '{{.Name}}')" || {
        echo "Could not list the example volumes"
        return 1
    }
    removed=0
    while IFS= read -r name; do
        [[ "${name}" == example-* ]] || continue
        if ! vm-podshift-run "${vm}" podman volume rm "${name}" >/dev/null; then
            write-log "${run_dir}" cleanup-examples "podman volume rm ${name} failed"
            echo "Could not remove the volume ${name}; is a container still using it?"
            return 1
        fi
        removed=$((removed + 1))
    done <<< "${labeled}"
    write-log "${run_dir}" cleanup-examples "example volume files removed, ${removed} volumes removed"
    echo "NOTE: ${removed} example volumes removed"
    return 0
}
