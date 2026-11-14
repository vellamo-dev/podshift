#!/usr/bin/env bash
# @file: 550-check-example-containers.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example containers present.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every example container exists for the podshift user, in the expected state.
# @details:
#   The names and states come from example-container-lines: running for the Quadlet containers,
#   exited for the containers of the user services, and the state named in unmanaged.list.
# @arg: $1 - the run folder.
# @stdout: NOTE with the containers and their states, or the wrong ones.
# @exitcode: 0 if all exist in the expected state, 2 otherwise, 3 if the VM is not running.
check-example-containers() {
    local run_dir vm dir line name want got
    local -a wrong seen
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/containers"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    wrong=()
    seen=()
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        want="${line#* }"
        got="$(vm-podshift-run "${vm}" podman container inspect --format '{{.State.Status}}' "${name}" 2>/dev/null)" || got="missing"
        # podman inspect says stopped for an exited container after cleanup; podman ps says exited.
        [[ "${got}" == "stopped" ]] && got="exited"
        if [[ "${got}" == "${want}" ]]; then
            seen+=("${name} (${got})")
        else
            wrong+=("${name} (${got:-missing}, want ${want})")
        fi
    done <<< "$(example-container-lines "${dir}")"
    if [[ "${#wrong[@]}" -gt 0 ]]; then
        write-log "${run_dir}" postinstall-examples "wrong containers: ${wrong[*]}"
        echo "Missing or in the wrong state: ${wrong[*]}"
        echo "Fix: ./test postinstall-examples"
        return 2
    fi
    write-log "${run_dir}" postinstall-examples "${#seen[@]} example containers exist: ${seen[*]}"
    echo "NOTE: ${#seen[@]} example containers exist: ${seen[*]}"
    return 0
}
