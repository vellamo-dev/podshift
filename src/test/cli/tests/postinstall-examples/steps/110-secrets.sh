#!/usr/bin/env bash
# @file: 110-secrets.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example secrets added.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Adds the example secrets, before any example container that uses them.
# @details:
#   Creates each secret in secrets.list with podman secret create --env when it does not exist, with
#   the fake value example-not-a-real-secret and the podshift.example=1 label. Runs first, so the
#   containers step can start example-secret-quadlet and run example-secret-stopped, which use
#   them. Existing secrets are kept, so it can run again.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was added, or the problem.
# @exitcode: 0 if all were added, 1 on an error, 3 if the VM is not running.
secrets() {
    local run_dir vm dir name line count err
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/secrets"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    count=0
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        vm-podshift-run "${vm}" podman secret exists "${name}" && continue
        # The value comes from an environment variable, so it never needs a file or stdin in the VM.
        if ! err="$(vm-podshift-run "${vm}" env PODSHIFT_EXAMPLE_SECRET=example-not-a-real-secret \
            podman secret create --env --label podshift.example=1 "${name}" PODSHIFT_EXAMPLE_SECRET 2>&1 >/dev/null)"; then
            write-log "${run_dir}" postinstall-examples "podman secret create ${name} failed: ${err}"
            echo "Could not create the secret ${name}: ${err}"
            return 1
        fi
        count=$((count + 1))
    done <<< "$(example-network-lines "${dir}/secrets.list")"
    write-log "${run_dir}" postinstall-examples "example secrets in place, ${count} secrets added"
    echo "NOTE: example secrets in place"
    return 0
}
