#!/usr/bin/env bash
# @file: load-podshift-conf-runtime.sh
# @dir: /opt/podshift/fn
# @group: runtime
# @description: Loads (sources and exports) the PodShift runtime configuration.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3188B5479489:-}" ]]; then
    DIR_3188B5479489="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3188B5479489
fi

# @description: Loads (sources and exports) the PodShift runtime configuration.
# @exitcode: 0 on success, 1 if PODSHIFT_RUNTIME_CONF is not defined.
load-podshift-conf-runtime() {
    local path_r_cnf_file
    # Load main config first to resolve PODSHIFT_RUNTIME_CONF
    # shellcheck source=./load-podshift-conf-main.sh
    source "${DIR_3188B5479489}/load-podshift-conf-main.sh" --now
    if [ -z "${PODSHIFT_RUNTIME_CONF:-}" ]; then
        echo "Error: PODSHIFT_RUNTIME_CONF is not defined." >&2
        return 1
    fi
    # Custom (CD manager) TSV_* variables first.
    if [ -n "${PODSHIFT_TSV_CONF:-}" ] && [ -f "${PODSHIFT_TSV_CONF}" ]; then
        set -a
        # shellcheck source=../../home/podshift/.config/podshift/tsv.conf
        source "${PODSHIFT_TSV_CONF}"
        set +a
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

# Executes only when called or sourced with --now
case "${1:-}" in
    --now) load-podshift-conf-runtime ;;
esac
