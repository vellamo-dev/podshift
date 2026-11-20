#!/usr/bin/env bash
# @file: load-podshift-conf-runtime.sh
# @source-dir: src/server/opt/podshift/fn
# @dest-dir: /opt/podshift/fn
# @host-edit: no
# @group: runtime
# @category: helper
# @description: Loads and exports the PodShift runtime configuration (tsv.conf as data, then runtime.conf).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3188B5479489:-}" ]]; then
    DIR_3188B5479489="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3188B5479489
fi

# @description: Loads and exports the PodShift runtime configuration (tsv.conf as data, then runtime.conf).
# @details:
#   The custom TSV_* values in tsv.conf, which the podshift user can write, are read as data with
#   read-tsv-conf-lines: only TSV_NAME=value lines are set, and nothing in the file is run.
#   runtime.conf, which is owned by root, is sourced last, so its values win.
# @exitcode: 0 on success, 1 if PODSHIFT_RUNTIME_CONF is not defined.
load-podshift-conf-runtime() {
    local path_r_cnf_file
    # Load main config first to resolve PODSHIFT_RUNTIME_CONF
    # shellcheck source=./load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_3188B5479489}/load-podshift-conf-main.sh"
    load-podshift-conf-main
    if [ -z "${PODSHIFT_RUNTIME_CONF:-}" ]; then
        echo "Error: PODSHIFT_RUNTIME_CONF is not defined." >&2
        return 1
    fi
    # Custom (CD manager) TSV_* variables first, read as data and never sourced.
    if [ -n "${PODSHIFT_TSV_CONF:-}" ] && [ -f "${PODSHIFT_TSV_CONF}" ]; then
        # shellcheck source=./utils/read-tsv-conf-lines.sh
        declare -F read-tsv-conf-lines >/dev/null || source "${DIR_3188B5479489}/utils/read-tsv-conf-lines.sh"
        read-tsv-conf-lines "${PODSHIFT_TSV_CONF}" || true
    fi

    # System runtime variables last (they win).
    path_r_cnf_file="${PODSHIFT_RUNTIME_CONF}"
    if [ -f "${path_r_cnf_file}" ]; then
        set -a
        # shellcheck source=../assets/tpl/runtime.conf
        source "${path_r_cnf_file}"
        set +a
    fi
}
