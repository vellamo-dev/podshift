#!/usr/bin/env bash
# @file: vm-run-stdin.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Runs a command as root in a VM, passing through the caller's stdin.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs a command as root in a VM over SSH, with the caller's stdin passed through.
# @details:
#   Same as vm-run, but stdin is not closed, so a password or other secret can be piped to the
#   remote command and never appear in the argument list.
# @arg: $1 - the VM name.
# @arg: $2... - the command and its arguments.
# @stdout: the command output.
# @stderr: a message if the VM has no IP address yet.
# @exitcode: the command's exit code, or 255 if SSH could not connect.
vm-run-stdin() {
    local name ip
    name="${1}"
    shift
    ip="$(vm-ip "${name}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${name} has no IP address yet" >&2
        return 255
    fi
    ssh -i "${HOME}/.ssh/podshift-test-vm" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -p "$(vm-ssh-port "${ip}")" "root@${ip}" "$@"
}
