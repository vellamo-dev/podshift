#!/usr/bin/env bash
# @file: vm-virsh.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Runs virsh on the system libvirt.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs virsh on qemu:///system, with stdin from /dev/null.
# @details:
#   qemu:///system is the libvirt that the libvirt group may use without a password. With stdin
#   from /dev/null, virsh never waits for input.
# @arg: $@ - the virsh arguments, for example domstate NAME.
# @stdout: the virsh output.
# @exitcode: the exit code of virsh.
vm-virsh() {
    virsh -c qemu:///system "$@" </dev/null
}
