#!/usr/bin/env bash
# @file: 501-registries.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/500-network
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/500-network
# @host-edit: no
# @group: health-check
# @category: check
# @title: Registries
# @run-as: any
# @description: Verifies the image registries are reachable.
# @rationale: Without them, container images cannot be pulled.
# @fix: Check the network, and PODSHIFT_REGISTRIES in main.conf.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the registries check.
# @stdout: one TSV line: registries<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-registries() {
    local -a hosts
    local host total reachable
    IFS=',' read -r -a hosts <<< "${PODSHIFT_REGISTRIES:-quay.io}"
    total=${#hosts[@]}
    reachable=0
    for host in "${hosts[@]}"; do
        curl -s -o /dev/null --max-time 3 "https://${host}/" 2>/dev/null && reachable=$((reachable + 1))
    done
    if (( reachable == total )); then
        printf 'registries\tOK\tall reachable\n'
        return 0
    elif (( reachable > 0 )); then
        printf 'registries\tWARN\t%d of %d reachable\n' "${reachable}" "${total}"
        return 1
    fi
    printf 'registries\tFAIL\tnone reachable\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-registries
