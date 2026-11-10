#!/usr/bin/env bash
# @file: 402-quadlet-dirs.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/400-config
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/400-config
# @host-edit: no
# @group: health-check
# @category: check
# @title: Quadlet directories
# @run-as: podshift
# @description: Verifies the quadlet pipeline directories exist.
# @rationale: Without them, quadlets cannot move through validation and installation.
# @fix: Reinstall PodShift: sudo dnf reinstall podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_CFFA6C150237:-}" ]]; then
    DIR_CFFA6C150237="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_CFFA6C150237
fi

# @description: Runs the quadlet-dirs check.
# @stdout: one TSV line: quadlet-dirs<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-quadlet-dirs() {
    local var dir missing unset_vars
    # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_CFFA6C150237}/../../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    missing=""
    unset_vars=""
    for var in PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR PODSHIFT_QUADLET_SOURCE_DIR PODSHIFT_QUADLET_STAGING_DIR \
        PODSHIFT_QUADLET_REJECTED_DIR PODSHIFT_QUADLET_FAILED_DIR PODSHIFT_QUADLET_INSTALLED_BACKUP_DIR; do
        dir="${!var:-}"
        if [[ -z "${dir}" ]]; then
            unset_vars+="${unset_vars:+, }${var}"
        elif [[ ! -d "${dir}" ]]; then
            missing+="${missing:+, }${dir}"
        fi
    done
    if [[ -n "${missing}" ]]; then
        printf 'quadlet-dirs\tFAIL\t%s missing\n' "${missing}"
        return 2
    fi
    if [[ -n "${unset_vars}" ]]; then
        printf 'quadlet-dirs\tWARN\t%s not set, see /opt/podshift/conf/main.conf\n' "${unset_vars}"
        return 1
    fi
    printf 'quadlet-dirs\tOK\tall present\n'
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-quadlet-dirs
