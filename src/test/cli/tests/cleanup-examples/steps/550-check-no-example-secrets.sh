#!/usr/bin/env bash
# @file: 550-check-no-example-secrets.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: No example secrets left.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that no example secret is left for the podshift user.
# @details:
#   The containers that used them are checked by the example containers check.
# @arg: $1 - the run folder.
# @stdout: NOTE if nothing is left, or what is left.
# @exitcode: 0 if nothing is left, 2 if something is left, 3 if the VM is not running.
check-no-example-secrets() {
    local run_dir vm dir line name
    local -a left
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/secrets"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    left=()
    while IFS= read -r line; do
        name="${line%% *}"
        [[ -n "${name}" ]] || continue
        vm-podshift-run "${vm}" podman secret exists "${name}" && left+=("secret ${name}")
    done <<< "$(example-network-lines "${dir}/secrets.list")"
    if [[ "${#left[@]}" -gt 0 ]]; then
        write-log "${run_dir}" cleanup-examples "left: ${left[*]}"
        echo "Still there: ${left[*]}"
        echo "Fix: ./test cleanup-examples"
        return 2
    fi
    write-log "${run_dir}" cleanup-examples "no example secrets left"
    echo "NOTE: no example secrets left"
    return 0
}
