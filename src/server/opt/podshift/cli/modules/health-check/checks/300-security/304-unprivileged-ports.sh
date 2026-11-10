#!/usr/bin/env bash
# @file: 304-unprivileged-ports.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/300-security
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/300-security
# @host-edit: no
# @group: health-check
# @category: check
# @title: Unprivileged ports
# @run-as: any
# @description: Verifies the unprivileged-ports sysctl.
# @rationale: Without it, rootless containers cannot bind low ports.
# @fix: sudo sysctl --system
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the unprivileged-ports check.
# @stdout: one TSV line: unprivileged-ports<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-unprivileged-ports() {
    if [[ "$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null)" == "80" ]]; then
        printf 'unprivileged-ports\tOK\tsysctl applied\n'
        return 0
    fi
    printf 'unprivileged-ports\tFAIL\tip_unprivileged_port_start is not 80\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-unprivileged-ports
