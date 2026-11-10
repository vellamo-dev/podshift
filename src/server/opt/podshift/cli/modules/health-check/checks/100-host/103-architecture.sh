#!/usr/bin/env bash
# @file: 103-architecture.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Architecture
# @run-as: any
# @description: Reports the CPU architecture.
# @rationale: Container images must match the CPU architecture to run.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the architecture check.
# @stdout: one TSV line: architecture<TAB><status><TAB><detail>.
# @exitcode: 0 = ran.

health-check-architecture() {
    printf 'architecture\tOK\t%s\n' "$(uname -m 2>/dev/null)"
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-architecture
