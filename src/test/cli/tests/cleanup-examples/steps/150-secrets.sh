#!/usr/bin/env bash
# @file: 150-secrets.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: Example secrets removed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the example secrets.
# @details:
#   Runs last, after the containers step has removed every example container, including
#   example-secret-quadlet and example-secret-stopped, which use the secrets. Removes each secret in
#   secrets.list that exists and has the podshift.example=1 label; other secrets are kept. Secret
#   values are never read.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was removed, or the problem.
# @exitcode: 0 if all were removed, 1 on an error, 3 if the VM is not running.
secrets() {
    local run_dir vm dir line name label removed
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/secrets"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    removed=0
    while IFS= read -r line; do
        name="${line%% *}"
        [[ "${name}" == example-* ]] || continue
        vm-podshift-run "${vm}" podman secret exists "${name}" || continue
        # No spaces in the format: ssh joins the arguments into one remote command line, so
        # {{index .Spec.Labels "podshift.example"}} would be split. Prints map[podshift.example:1 ...].
        label="$(vm-podshift-run "${vm}" podman secret inspect --format '{{.Spec.Labels}}' "${name}" 2>/dev/null)"
        label="${label#map[}"
        label="${label%]}"
        if [[ " ${label} " != *" podshift.example:1 "* ]]; then
            write-log "${run_dir}" cleanup-examples "secret ${name} kept: no podshift.example=1 label"
            echo "NOTE: kept the secret ${name}, it has no podshift.example=1 label"
            continue
        fi
        if ! vm-podshift-run "${vm}" podman secret rm "${name}" >/dev/null; then
            write-log "${run_dir}" cleanup-examples "podman secret rm ${name} failed"
            echo "Could not remove the secret ${name}"
            return 1
        fi
        removed=$((removed + 1))
    done <<< "$(example-network-lines "${dir}/secrets.list")"
    write-log "${run_dir}" cleanup-examples "${removed} example secrets removed"
    echo "NOTE: ${removed} example secrets removed"
    return 0
}
