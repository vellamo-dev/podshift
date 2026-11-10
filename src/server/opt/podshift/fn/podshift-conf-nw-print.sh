#!/usr/bin/env bash
# @file: podshift-conf-nw-print.sh
# @source-dir: src/server/opt/podshift/fn
# @dest-dir: /opt/podshift/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Loads and prints the host's external IPv4 addresses (TSV_NW1..8).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Loads TSV_NW1..8, then prints the defined ones.
# @stdout: prints the defined TSV_NW* variables.
podshift-conf-nw-print() {
    local i var_name var_value
    # shellcheck source=./load-podshift-conf-nw.sh
    declare -F load-podshift-conf-nw >/dev/null || source /opt/podshift/fn/load-podshift-conf-nw.sh
    load-podshift-conf-nw
    echo -e "\nSystem has the following IPv4s defined:\n"
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        [[ -n "${var_value}" ]] && echo "  ${var_name}=${var_value}"
    done
    echo ""
}
