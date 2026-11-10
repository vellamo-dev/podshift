#!/usr/bin/env bash
# @file: 104-hostname.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Hostname
# @run-as: any
# @description: Reports the machine hostname.
# @rationale: A clear hostname identifies the server in logs, monitoring and Cockpit.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the hostname check.
# @stdout: one TSV line: hostname<TAB><status><TAB><detail>.
# @exitcode: 0 = ran.

health-check-hostname() {
    printf 'hostname\tOK\t%s\n' "$(hostname 2>/dev/null)"
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-hostname
