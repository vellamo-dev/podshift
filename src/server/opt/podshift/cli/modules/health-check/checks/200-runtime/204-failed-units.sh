#!/usr/bin/env bash
# @file: 204-failed-units.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/200-runtime
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/200-runtime
# @host-edit: no
# @group: health-check
# @category: check
# @title: Failed units
# @run-as: podshift
# @description: Verifies no failed user units.
# @rationale: Failed units mean a service is down.
# @fix: As the podshift user: failed-services to see them, then reset-failed to clear them.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the failed-units check.
# @stdout: one TSV line: failed-units<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-failed-units() {
    if ! systemctl --user list-units --failed --no-legend 2>/dev/null | grep -q .; then
        printf 'failed-units\tOK\tnone\n'
        return 0
    fi
    printf 'failed-units\tFAIL\tfailed user units present\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-failed-units
