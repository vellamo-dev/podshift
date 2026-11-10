#!/usr/bin/env bash
# @file: vm-copy.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Copies a host file into a VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies a host file into a folder in the VM as root, with scp.
# @details:
#   It uses the test VM key ~/.ssh/podshift-test-vm, on port 22 or 1022 (see vm-ssh-port).
# @arg: $1 - the VM name.
# @arg: $2 - the host file.
# @arg: $3 - the folder in the VM.
# @stderr: a message if the VM has no IP address yet.
# @exitcode: 0 if copied, otherwise the exit code of scp, or 255 if the VM has no IP address.
vm-copy() {
    local ip
    ip="$(vm-ip "${1}")"
    if [[ -z "${ip}" ]]; then
        echo "The VM ${1} has no IP address yet" >&2
        return 255
    fi
    scp -q -i "${HOME}/.ssh/podshift-test-vm" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -P "$(vm-ssh-port "${ip}")" \
        "${2}" "root@${ip}:${3}/" </dev/null
}
