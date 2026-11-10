#!/usr/bin/env bash
# @file: 580-check-disk-space.sh
# @source-dir: src/test/cli/tests/host-check/steps
# @group: test
# @category: step
# @description: Free disk space.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the repository disk has at least TST_MIN_DISK_GB free.
# @stdout: the free space, and how to fix it if too little.
# @arg: $1 - the run folder.
# @exitcode: 0 if there is enough space, 3 otherwise (cannot run here).
check-disk-space() {
    local run_dir free_gb
    run_dir="${1}"
    free_gb="$(df -Pk . | awk 'NR == 2 { print int($4 / 1048576) }')"
    write-log "${run_dir}" host-check "Free disk space: ${free_gb} GB, needs ${TST_MIN_DISK_GB} GB"
    echo "NOTE: ${free_gb} GB free"
    [[ "${free_gb}" -ge "${TST_MIN_DISK_GB}" ]] && return 0
    echo "${free_gb} GB free, ${TST_MIN_DISK_GB} GB needed"
    echo "Fix: free up disk space"
    return 3
}
