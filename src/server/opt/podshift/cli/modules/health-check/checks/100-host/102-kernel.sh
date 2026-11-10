#!/usr/bin/env bash
# @file: 102-kernel.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Kernel
# @run-as: any
# @description: Reports the running kernel version.
# @rationale: Rootless containers rely on kernel features such as user namespaces and cgroups v2.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the kernel check.
# @stdout: one TSV line: kernel<TAB><status><TAB><detail>.
# @exitcode: 0 = ran.

health-check-kernel() {
    printf 'kernel\tOK\t%s\n' "$(uname -r 2>/dev/null)"
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-kernel
