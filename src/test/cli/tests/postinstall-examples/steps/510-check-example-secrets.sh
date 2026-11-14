#!/usr/bin/env bash
# @file: 510-check-example-secrets.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example secrets present.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that every example secret exists with the podshift.example=1 label.
# @details:
#   The secrets are the names in secrets.list. The containers that use them are checked by the
#   example containers check. Secret values are never read.
# @arg: $1 - the run folder.
# @stdout: NOTE with the number of secrets, or the missing ones.
# @exitcode: 0 if all exist, 2 otherwise, 3 if the VM is not running.
check-example-secrets() {
    local run_dir vm dir line name label
    local -a names wrong
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/secrets"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    names=()
    wrong=()
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        names+=("${name}")
        if ! vm-podshift-run "${vm}" podman secret exists "${name}"; then
            wrong+=("${name} (missing)")
            continue
        fi
        # No spaces in the format: ssh joins the arguments into one remote command line, so
        # {{index .Spec.Labels "podshift.example"}} would be split. Prints map[podshift.example:1 ...].
        label="$(vm-podshift-run "${vm}" podman secret inspect --format '{{.Spec.Labels}}' "${name}" 2>/dev/null)"
        label="${label#map[}"
        label="${label%]}"
        [[ " ${label} " == *" podshift.example:1 "* ]] || wrong+=("${name} (no podshift.example=1 label)")
    done <<< "$(example-network-lines "${dir}/secrets.list")"
    if [[ "${#wrong[@]}" -gt 0 ]]; then
        write-log "${run_dir}" postinstall-examples "wrong secrets: ${wrong[*]}"
        echo "Missing or wrong: ${wrong[*]}"
        echo "Fix: ./test postinstall-examples"
        return 2
    fi
    write-log "${run_dir}" postinstall-examples "${#names[@]} example secrets exist: ${names[*]}"
    echo "NOTE: ${#names[@]} example secrets exist"
    return 0
}
