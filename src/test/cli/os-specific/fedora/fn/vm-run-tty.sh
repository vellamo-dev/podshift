#!/usr/bin/env bash
# @file: vm-run-tty.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Runs a command as root in a VM with a terminal.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs a command as root in a VM over SSH with a terminal and TERM=xterm-256color, the way a person sees it.
# @arg: $1 - the VM name.
# @arg: $2... - the command and its arguments.
# @stdout: the raw terminal output, with color codes and carriage returns.
# @exitcode: the command's exit code, or 255 if SSH could not connect.
vm-run-tty() {
    local name ip
    name="${1}"
    shift
    ip="$(vm-ip "${name}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${name} has no IP address yet" >&2
        return 255
    fi
    ssh -tt -i "${HOME}/.ssh/podshift-test-vm" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -p "$(vm-ssh-port "${ip}")" "root@${ip}" env TERM=xterm-256color "$@" </dev/null
}
