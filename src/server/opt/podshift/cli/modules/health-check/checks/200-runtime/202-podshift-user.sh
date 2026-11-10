#!/usr/bin/env bash
# @file: 202-podshift-user.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/200-runtime
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/200-runtime
# @host-edit: no
# @group: health-check
# @category: check
# @title: PodShift user
# @run-as: any
# @description: Verifies the podshift user identity.
# @rationale: The fixed UID, home, and lingering are required for rootless operation.
# @fix: Reinstall PodShift: sudo dnf reinstall podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the podshift-user check.
# @stdout: one TSV line: podshift-user<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-podshift-user() {
    if [[ "$(id -u podshift 2>/dev/null)" == "300" ]] \
        && [[ -d /home/podshift ]] \
        && [[ -f /var/lib/systemd/linger/podshift ]]; then
        printf 'podshift-user\tOK\tUID 300, home, lingering\n'
        return 0
    fi
    printf 'podshift-user\tFAIL\tUID 300, home, or lingering missing\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-podshift-user
