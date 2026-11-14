#!/usr/bin/env bash
# @file: 510-check-no-example-containers.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: No example containers left.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that no example container, container file or container service file is left for the podshift user.
# @arg: $1 - the run folder.
# @stdout: NOTE if nothing is left, or what is left.
# @exitcode: 0 if nothing is left, 2 if something is left, 3 if the VM is not running.
check-no-example-containers() {
    local run_dir vm dir file base line name
    local -a left
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/containers"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    left=()
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-run "${vm}" test -e "/home/podshift/.config/containers/systemd/${base}" && left+=("${base}")
    done
    for file in "${dir}"/example-*.service; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-run "${vm}" test -e "/home/podshift/.config/systemd/user/${base}" && left+=("${base}")
    done
    while IFS= read -r line; do
        name="${line%% *}"
        [[ -n "${name}" ]] || continue
        vm-podshift-run "${vm}" podman container exists "${name}" && left+=("container ${name}")
    done <<< "$(example-container-lines "${dir}")"
    if [[ "${#left[@]}" -gt 0 ]]; then
        write-log "${run_dir}" cleanup-examples "left: ${left[*]}"
        echo "Still there: ${left[*]}"
        echo "Fix: ./test cleanup-examples"
        return 2
    fi
    write-log "${run_dir}" cleanup-examples "no example containers or files left"
    echo "NOTE: no example containers or files left"
    return 0
}
