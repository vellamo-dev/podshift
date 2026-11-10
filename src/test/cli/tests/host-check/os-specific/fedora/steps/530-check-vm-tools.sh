#!/usr/bin/env bash
# @file: 530-check-vm-tools.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/fedora/steps
# @group: test
# @category: step
# @description: VM tools.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the packages for creating and running the test VM are installed.
# @arg: $1 - the run folder.
# @stdout: each missing package and one Fix line for all of them.
# @exitcode: 0 if all are installed, 3 otherwise (cannot run here).
check-vm-tools() {
    local run_dir pkg
    local -a missing
    run_dir="${1}"
    missing=()
    for pkg in qemu-kvm libvirt-daemon-kvm libvirt-client virt-install qemu-img guestfs-tools xorriso; do
        rpm -q "${pkg}" >/dev/null 2>&1 && continue
        echo "${pkg} not installed"
        missing+=("${pkg}")
    done
    write-log "${run_dir}" host-check "VM tools missing: ${missing[*]:-none}"
    (( ${#missing[@]} == 0 )) && return 0
    echo "Fix: ${TST_INSTALL_CMD} ${missing[*]}"
    return 3
}
