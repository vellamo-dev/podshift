#!/usr/bin/env bash
# @file: 540-check-example-volumes.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example volumes present.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every example volume and example volume container exists for the podshift user.
# @details:
#   The expected volumes are the VolumeName of each example .volume file, the named volumes of
#   each example .container file, and each name in unmanaged.list. The expected containers are
#   the ContainerName= of each example .container file.
# @arg: $1 - the run folder.
# @stdout: NOTE with the number of volumes, or the missing ones.
# @exitcode: 0 if all exist, 2 if any is missing, 3 if the VM is not running.
check-example-volumes() {
    local run_dir vm dir file line name
    local -a names missing
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/volumes"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    names=()
    missing=()
    for file in "${dir}"/example-*.volume; do
        [[ -f "${file}" ]] || continue
        name="$(sed -n 's/^VolumeName=//p' "${file}" | tail -n 1)"
        names+=("${name:-systemd-$(basename "${file}" .volume)}")
    done
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        while IFS= read -r name; do
            [[ "${name}" == example-* ]] && names+=("${name}")
        done <<< "$(sed -n 's/^Volume=\([^:/][^:]*\):.*/\1/p' "${file}")"
        name="$(sed -n 's/^ContainerName=//p' "${file}" | tail -n 1)"
        name="${name:-systemd-$(basename "${file}" .container)}"
        vm-podshift-run "${vm}" podman container exists "${name}" || missing+=("container ${name}")
    done
    while IFS= read -r line; do
        [[ -n "${line}" ]] && names+=("${line%% *}")
    done <<< "$(example-network-lines "${dir}/unmanaged.list")"
    for name in "${names[@]}"; do
        vm-podshift-run "${vm}" podman volume exists "${name}" || missing+=("${name}")
    done
    if [[ "${#missing[@]}" -gt 0 ]]; then
        write-log "${run_dir}" postinstall-examples "missing volumes: ${missing[*]}"
        echo "Missing: ${missing[*]}"
        echo "Fix: ./test postinstall-examples"
        return 2
    fi
    write-log "${run_dir}" postinstall-examples "${#names[@]} example volumes exist: ${names[*]}"
    echo "NOTE: ${#names[@]} example volumes exist"
    return 0
}
