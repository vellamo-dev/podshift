#!/usr/bin/env bash
# @file: 520-check-kvm.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/fedora/steps
# @group: test
# @category: step
# @description: KVM usable.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that KVM is usable, so the test VM runs at full speed.
# @arg: $1 - the run folder.
# @stdout: NOTE with the CPU count and memory, or the problem and a Fix line.
# @exitcode: 0 if KVM is usable, 3 otherwise (cannot run here).
check-kvm() {
    local run_dir cpus mem_gb
    run_dir="${1}"
    cpus="$(nproc)"
    mem_gb="$(awk '/MemTotal/ { printf "%d", $2 / 1048576 }' /proc/meminfo)"
    write-log "${run_dir}" host-check "KVM: $(ls -l /dev/kvm 2>/dev/null || echo '/dev/kvm missing'), ${cpus} CPUs, ${mem_gb} GB memory"
    if [[ ! -e /dev/kvm ]]; then
        echo "/dev/kvm not found"
        echo "Fix: turn on virtualization (VT-x or AMD-V) in the BIOS or UEFI"
        return 3
    fi
    if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
        echo "/dev/kvm is not usable by $(id -un)"
        echo "Fix: sudo usermod -aG kvm $(id -un), then log out and in again"
        return 3
    fi
    echo "NOTE: ${cpus} CPUs, ${mem_gb} GB memory"
}
