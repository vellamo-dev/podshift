#!/usr/bin/env bash
# @file: 401-drop-dir.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/400-config
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/400-config
# @host-edit: no
# @group: health-check
# @category: check
# @title: Drop directory
# @run-as: podshift
# @description: Verifies the drop directory exists.
# @rationale: Without it, Quadlets cannot be dropped for installation.
# @fix: Reinstall PodShift: sudo dnf reinstall podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B69418CE17CE:-}" ]]; then
    DIR_B69418CE17CE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B69418CE17CE
fi

# @description: Runs the drop-dir check.
# @stdout: one TSV line: drop-dir<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-drop-dir() {
    local dir
    # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_B69418CE17CE}/../../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    [[ -n "${PODSHIFT_DROP_DIR:-}" ]] || { printf 'drop-dir\tWARN\tPODSHIFT_DROP_DIR is not set, see /opt/podshift/conf/main.conf\n'; return 1; }
    dir="${PODSHIFT_DROP_DIR}"
    if [[ -d "${dir}" ]]; then
        printf 'drop-dir\tOK\tpresent\n'
        return 0
    fi
    printf 'drop-dir\tFAIL\t%s missing\n' "${dir}"
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-drop-dir
