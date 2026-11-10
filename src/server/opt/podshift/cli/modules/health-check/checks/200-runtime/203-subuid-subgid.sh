#!/usr/bin/env bash
# @file: 203-subuid-subgid.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/200-runtime
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/200-runtime
# @host-edit: no
# @group: health-check
# @category: check
# @title: User namespaces
# @run-as: any
# @description: Verifies the user-namespace mappings.
# @rationale: Without them, rootless containers cannot map user IDs.
# @fix: Reinstall PodShift: sudo dnf reinstall podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the subuid-subgid check.
# @stdout: one TSV line: subuid-subgid<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-subuid-subgid() {
    if grep -q '^podshift:' /etc/subuid 2>/dev/null \
        && grep -q '^podshift:' /etc/subgid 2>/dev/null; then
        printf 'subuid-subgid\tOK\tmappings present\n'
        return 0
    fi
    printf 'subuid-subgid\tFAIL\t/etc/subuid or /etc/subgid entry missing\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-subuid-subgid
