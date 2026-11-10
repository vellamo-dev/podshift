#!/usr/bin/env bash
# @file: 105-disk.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/100-host
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/100-host
# @host-edit: no
# @group: health-check
# @category: check
# @title: Disk space
# @run-as: podshift
# @description: Verifies the PodShift storage filesystem has free space.
# @rationale: Without free space, container images and volumes cannot be written.
# @fix: Free disk space, for example remove unused images with podman image prune.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_979E0A054966:-}" ]]; then
    DIR_979E0A054966="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_979E0A054966
fi

# @description: Runs the disk check.
# @stdout: one TSV line: disk<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-disk() {
    local dir pct
    # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_979E0A054966}/../../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    [[ -n "${PODSHIFT_DROP_DIR:-}" ]] || { printf 'disk\tWARN\tPODSHIFT_DROP_DIR is not set, see /opt/podshift/conf/main.conf\n'; return 1; }
    dir="${PODSHIFT_DROP_DIR}"
    pct="$(df -P "${dir}" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"
    if [[ -z "${pct}" ]]; then
        printf 'disk\tWARN\tstorage usage unknown\n'
        return 1
    fi
    if [[ "${pct}" -lt 80 ]]; then
        printf 'disk\tOK\t%s%% used\n' "${pct}"
        return 0
    elif [[ "${pct}" -lt 95 ]]; then
        printf 'disk\tWARN\t%s%% used\n' "${pct}"
        return 1
    fi
    printf 'disk\tFAIL\t%s%% used\n' "${pct}"
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-disk
