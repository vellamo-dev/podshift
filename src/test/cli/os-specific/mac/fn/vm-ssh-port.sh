#!/usr/bin/env bash
# @file: vm-ssh-port.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Prints the SSH port of a VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the first port in TST_VM_SSH_PORTS where root can log in to the VM.
# @details:
#   This way SSH works before PodShift is installed (22) and after (1022). Prints the last port if
#   none works, so SSH shows its own error. It tests with a real SSH login, because sshd blocks an
#   address for a while after connections that never log in.
# @arg: $1 - the VM IP address.
# @stdout: the port number.
vm-ssh-port() {
    local port last
    for port in ${TST_VM_SSH_PORTS}; do
        last="${port}"
        if ssh -i "${HOME}/.ssh/podshift-test-vm" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o LogLevel=QUIET -o ConnectTimeout=2 -p "${port}" "root@${1}" true </dev/null >/dev/null 2>&1; then
            echo "${port}"
            return 0
        fi
    done
    echo "${last}"
}
