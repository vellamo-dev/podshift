#!/usr/bin/env bash
# @file: 303-selinux.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/300-security
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/300-security
# @host-edit: no
# @group: health-check
# @category: check
# @title: SELinux
# @run-as: any
# @description: Verifies SELinux is enforcing.
# @rationale: Without it, container confinement is not enforced.
# @fix: sudo setenforce 1, and set SELINUX=enforcing in /etc/selinux/config
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the selinux check.
# @stdout: one TSV line: selinux<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-selinux() {
    if [[ "$(getenforce 2>/dev/null)" == "Enforcing" ]]; then
        printf 'selinux\tOK\tenforcing\n'
        return 0
    fi
    printf 'selinux\tFAIL\tnot enforcing\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-selinux
