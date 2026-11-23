#!/usr/bin/env bash
# @file: podshift-network-print.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the derived external IPv4 addresses.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1C85D209A4DE:-}" ]]; then
    DIR_1C85D209A4DE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1C85D209A4DE
fi

# @description: Prints the derived external IPv4 addresses.
podshift-network-print() {
    local i var_name var_value
    # shellcheck source=../../../../fn/load-podshift-conf-nw.sh
    declare -F load-podshift-conf-nw >/dev/null || source "${DIR_1C85D209A4DE}/../../../../fn/load-podshift-conf-nw.sh"
    load-podshift-conf-nw
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        if [[ -n "${var_value}" ]]; then
            echo "${var_name}=${var_value}"
        fi
    done
    return 0
}
