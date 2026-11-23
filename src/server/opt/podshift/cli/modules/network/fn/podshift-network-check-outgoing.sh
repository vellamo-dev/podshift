#!/usr/bin/env bash
# @file: podshift-network-check-outgoing.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Probes outgoing access to the image registries in PODSHIFT_REGISTRIES.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F774BB5C7268:-}" ]]; then
    DIR_F774BB5C7268="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F774BB5C7268
fi

# @description: Probes outgoing access to the image registries in PODSHIFT_REGISTRIES.
# @details:
#   The hosts come from main.conf, the same list the registries health check probes, and each one
#   is probed with is-host-reachable. An empty list is a warning, not a failure: it is a missing
#   setting, and says nothing about the network itself.
# @stdout: prints one OK/FAIL line per host, or a line saying the list is not set.
# @exitcode: 0 = all reachable, 1 = some reachable or the list is not set, 2 = none reachable.
podshift-network-check-outgoing() {
    local -a hosts
    local host reachable total
    if ! command -v curl >/dev/null 2>&1; then
        echo "    curl not installed"
        return 1
    fi
    # shellcheck source=../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_F774BB5C7268}/../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    if [[ -z "${PODSHIFT_REGISTRIES:-}" ]]; then
        echo "    PODSHIFT_REGISTRIES is not set in main.conf"
        return 1
    fi
    IFS=',' read -r -a hosts <<< "${PODSHIFT_REGISTRIES}"
    total=${#hosts[@]}
    reachable=0
    # shellcheck source=../../../../fn/network/is-host-reachable.sh
    declare -F is-host-reachable >/dev/null || source "${DIR_F774BB5C7268}/../../../../fn/network/is-host-reachable.sh"
    for host in "${hosts[@]}"; do
        if is-host-reachable "${host}"; then
            echo "    ${host}  OK"
            reachable=$((reachable + 1))
        else
            echo "    ${host}  FAIL"
        fi
    done
    if (( reachable == 0 )); then
        return 2
    elif (( reachable < total )); then
        return 1
    fi
    return 0
}
