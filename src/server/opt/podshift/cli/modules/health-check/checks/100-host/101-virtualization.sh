#!/usr/bin/env bash
# @file: 101-virtualization.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Virtualization
# @run-as: any
# @description: Reports whether the host is a VM and which hypervisor.
# @rationale: Bare metal, a VM and a container behave differently, so the platform explains other results.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the virtualization check.
# @stdout: one TSV line: virtualization<TAB><status><TAB><detail>.
# @exitcode: 0 = ran.

health-check-virtualization() {
    local virt vendor
    if [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
        if sysctl -n machdep.cpu.features 2>/dev/null | grep -q 'VMM'; then
            virt="VM"
        else
            virt="none"
        fi
    else
        virt="$(systemd-detect-virt 2>/dev/null)"
        if [[ -z "${virt}" ]]; then
            vendor="$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null)"
            [[ -n "${vendor}" ]] && virt="${vendor}" || virt="unknown"
        fi
    fi
    case "${virt}" in
        none)      printf 'virtualization\tOK\tbare metal\n' ;;
        apple)     printf 'virtualization\tOK\tApple Virtualization (VM)\n' ;;
        kvm|qemu)  printf 'virtualization\tOK\tKVM (QEMU)\n' ;;
        vmware)    printf 'virtualization\tOK\tVMware\n' ;;
        oracle)    printf 'virtualization\tOK\tVirtualBox\n' ;;
        microsoft) printf 'virtualization\tOK\tHyper-V\n' ;;
        xen)       printf 'virtualization\tOK\tXen\n' ;;
        *)         printf 'virtualization\tOK\t%s\n' "${virt}" ;;
    esac
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-virtualization
