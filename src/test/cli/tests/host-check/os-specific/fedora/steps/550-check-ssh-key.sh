#!/usr/bin/env bash
# @file: 550-check-ssh-key.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/fedora/steps
# @group: test
# @category: step
# @description: SSH key.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the test VM SSH key exists. cloud-init puts it in the test VM so the tests can log in.
# @arg: $1 - the run folder.
# @stdout: the problem and a Fix line when the key is missing.
# @exitcode: 0 if the key is found, 3 otherwise (cannot run here).
check-ssh-key() {
    local run_dir key
    run_dir="${1}"
    key="${HOME}/.ssh/podshift-test-vm"
    if [[ -f "${key}" && -f "${key}.pub" ]]; then
        write-log "${run_dir}" host-check "SSH key: ${key}"
        return 0
    fi
    write-log "${run_dir}" host-check "SSH key: ${key} missing"
    echo "No test VM SSH key ${key}"
    echo "Fix: ssh-keygen -t ed25519 -f ~/.ssh/podshift-test-vm -N \"\" -C \"podshift-test-vm\""
    return 3
}
