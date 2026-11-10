#!/usr/bin/env bash
# @file: vm-run.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Runs a command as root in a VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs a command as root in a VM over SSH.
# @details:
#   It uses the test VM key ~/.ssh/podshift-test-vm, on port 22 or 1022 (see vm-ssh-port). The VM
#   is new on every run, so its host key is not checked or saved. The arguments are joined and
#   split again inside the VM, so pass simple words, not quoted shell scripts.
# @arg: $1 - the VM name.
# @arg: $2... - the command and its arguments.
# @stdout: the command output.
# @stderr: a message if the VM has no IP address yet.
# @exitcode: the command's exit code, or 255 if SSH could not connect.
vm-run() {
    local name ip
    name="${1}"
    shift
    ip="$(vm-ip "${name}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${name} has no IP address yet" >&2
        return 255
    fi
    ssh -i "${HOME}/.ssh/podshift-test-vm" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -p "$(vm-ssh-port "${ip}")" "root@${ip}" "$@" </dev/null
}
