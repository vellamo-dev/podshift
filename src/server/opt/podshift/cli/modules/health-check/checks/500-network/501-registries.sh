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

if [[ -z "${DIR_DFD0C854B24E:-}" ]]; then
    DIR_DFD0C854B24E="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DFD0C854B24E
fi

# @description: Runs the registries check.
# @stdout: one TSV line: registries<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-registries() {
    local -a hosts
    local host total reachable
    # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_DFD0C854B24E}/../../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    if [[ -z "${PODSHIFT_REGISTRIES:-}" ]]; then
        printf 'registries\tWARN\tPODSHIFT_REGISTRIES is not set in main.conf\n'
        return 1
    fi
    IFS=',' read -r -a hosts <<< "${PODSHIFT_REGISTRIES}"
    total=${#hosts[@]}
    reachable=0
    # shellcheck source=../../../../../fn/network/is-host-reachable.sh
    declare -F is-host-reachable >/dev/null || source "${DIR_DFD0C854B24E}/../../../../../fn/network/is-host-reachable.sh"
    for host in "${hosts[@]}"; do
        is-host-reachable "${host}" && reachable=$((reachable + 1))
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
