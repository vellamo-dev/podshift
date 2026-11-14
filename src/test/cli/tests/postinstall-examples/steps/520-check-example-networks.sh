#!/usr/bin/env bash
# @file: 520-check-example-networks.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example networks present.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every example network exists for the podshift user.
# @details:
#   The expected names are the NetworkName of each example .network file, the network created by
#   each example .service file, and each name in unmanaged.list.
# @arg: $1 - the run folder.
# @stdout: NOTE with the number of networks, or the missing ones.
# @exitcode: 0 if all exist, 2 if any is missing, 3 if the VM is not running.
check-example-networks() {
    local run_dir vm dir file line name names missing
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/networks"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    names=()
    for file in "${dir}"/example-*.network; do
        [[ -f "${file}" ]] || continue
        name="$(sed -n 's/^NetworkName=//p' "${file}" | tail -n 1)"
        names+=("${name:-systemd-$(basename "${file}" .network)}")
    done
    for file in "${dir}"/example-*.service; do
        [[ -f "${file}" ]] || continue
        name="$(sed -n 's/^ExecStart=.*podman network create .* \(example-[A-Za-z0-9_.-]*\)$/\1/p' "${file}" | head -n 1)"
        [[ -n "${name}" ]] && names+=("${name}")
    done
    while IFS= read -r line; do
        [[ -n "${line}" ]] && names+=("${line%% *}")
    done <<< "$(example-network-lines "${dir}/unmanaged.list")"
    missing=()
    for name in "${names[@]}"; do
        vm-podshift-run "${vm}" podman network exists "${name}" || missing+=("${name}")
    done
    if [[ "${#missing[@]}" -gt 0 ]]; then
        write-log "${run_dir}" postinstall-examples "missing networks: ${missing[*]}"
        echo "Missing networks: ${missing[*]}"
        echo "Fix: ./test postinstall-examples"
        return 2
    fi
    write-log "${run_dir}" postinstall-examples "${#names[@]} example networks exist: ${names[*]}"
    echo "NOTE: ${#names[@]} example networks exist"
    return 0
}
