#!/usr/bin/env bash
# @file: podshift-network-reload.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Re-derives TSV_NW1..8 and prints export commands for the current shell.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_0B97338C1ECE:-}" ]]; then
    DIR_0B97338C1ECE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_0B97338C1ECE
fi

# @description: Re-derives TSV_NW1..8 and prints export commands for the current shell.
# @exitcode: 0 always.
podshift-network-reload() {
    local i var_name var_value
    # shellcheck source=../../../../fn/load-podshift-conf-nw.sh
    declare -F load-podshift-conf-nw >/dev/null || source "${DIR_0B97338C1ECE}/../../../../fn/load-podshift-conf-nw.sh"
    load-podshift-conf-nw
    echo "Apply to this shell with: eval \"\$(podshift nw reload)\"" >&2
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        if [[ -n "${var_value}" ]]; then
            printf 'export %s=%q\n' "${var_name}" "${var_value}"
        fi
    done
    return 0
}
