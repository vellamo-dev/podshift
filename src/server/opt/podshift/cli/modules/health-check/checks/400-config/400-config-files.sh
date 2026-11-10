#!/usr/bin/env bash
# @file: 400-config-files.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/400-config
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/400-config
# @host-edit: no
# @group: health-check
# @category: check
# @title: Config files
# @run-as: podshift
# @description: Verifies the runtime config file exists; a missing one is only a note.
# @rationale: Without them, PodShift cannot resolve its target-system values.
# @fix: podshift --help config
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_EBE9B1532A4F:-}" ]]; then
    DIR_EBE9B1532A4F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_EBE9B1532A4F
fi

# @description: Runs the config-files check.
# @stdout: one TSV line: config-files<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 3 = INFO.

health-check-config-files() {
    local runtime tsv missing
    # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_EBE9B1532A4F}/../../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    [[ -n "${PODSHIFT_RUNTIME_CONF:-}" ]] || { printf 'config-files\tWARN\tPODSHIFT_RUNTIME_CONF is not set, see /opt/podshift/conf/main.conf\n'; return 1; }
    [[ -n "${PODSHIFT_TSV_CONF:-}" ]] || { printf 'config-files\tWARN\tPODSHIFT_TSV_CONF is not set, see /opt/podshift/conf/main.conf\n'; return 1; }
    runtime="${PODSHIFT_RUNTIME_CONF}"
    tsv="${PODSHIFT_TSV_CONF}"
    missing=""
    [[ -f "${runtime}" ]] || missing="${runtime}"
    if [[ -n "${missing}" ]]; then
        printf 'config-files\tWARN\tmissing: %s\n' "${missing}"
        return 1
    fi
    if [[ ! -f "${tsv}" ]]; then
        printf 'config-files\tINFO\tno custom keys yet (%s)\n' "${tsv}"
        return 3
    fi
    printf 'config-files\tOK\tpresent\n'
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-config-files
