#!/usr/bin/env bash
# @file: 140-networks.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: Example networks removed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the example network units, removes their files, then removes the example networks.
# @details:
#   Units and files are taken from the example-*.network and example-*.service fixture names, so
#   no other file is touched. Networks are removed only when the name starts with example- and the
#   network has the podshift.example=1 label, or the name is listed in unmanaged.list. Networks are
#   removed without --force, so a network still used by a container is reported and kept.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or the problem.
# @exitcode: 0 if all were removed, 1 on an error, 3 if the VM is not running.
networks() {
    local run_dir vm dir file base name line labeled removed
    local -a names
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/networks"
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
    for file in "${dir}"/example-*.network; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-podshift-systemctl "${vm}" stop "${base%.network}-network.service" >/dev/null 2>&1 || true
        vm-run "${vm}" rm -f "/home/podshift/.config/containers/systemd/${base}" || { echo "Could not remove ${base}"; return 1; }
    done
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    vm-podshift-systemctl "${vm}" reset-failed >/dev/null 2>&1 || true
    names=()
    labeled="$(vm-podshift-run "${vm}" podman network ls --filter label=podshift.example=1 --format '{{.Name}}')" || {
        echo "Could not list the example networks"
        return 1
    }
    while IFS= read -r name; do
        [[ "${name}" == example-* ]] && names+=("${name}")
    done <<< "${labeled}"
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        if [[ " ${names[*]-} " != *" ${name} "* ]] && vm-podshift-run "${vm}" podman network exists "${name}"; then
            names+=("${name}")
        fi
    done <<< "$(example-network-lines "${dir}/unmanaged.list")"
    removed=0
    for name in "${names[@]}"; do
        if ! vm-podshift-run "${vm}" podman network rm "${name}" >/dev/null; then
            write-log "${run_dir}" cleanup-examples "podman network rm ${name} failed"
            echo "Could not remove the network ${name}; is a container still using it?"
            return 1
        fi
        removed=$((removed + 1))
    done
    vm-run "${vm}" rm -rf "${TST_EXAMPLES_VM_TMP}" || true
    write-log "${run_dir}" cleanup-examples "example network files removed, ${removed} networks removed"
    echo "NOTE: ${removed} example networks removed"
    return 0
}
