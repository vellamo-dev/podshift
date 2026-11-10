#!/usr/bin/env bash
# @file: 510-remove-rpms.sh
# @source-dir: src/test/cli/tests/clean-rpm-output/steps
# @group: test
# @category: step
# @description: Remove exported RPM packages.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes every .rpm file in the RPM share folder.
# @arg: $1 - the run folder.
# @stdout: NOTE with how many were removed, or none found.
# @exitcode: 0 if none are left, 1 otherwise.
remove-rpms() {
    local run_dir count
    run_dir="${1}"
    count="$(find "${TST_RPM_SHARE_DIR}" -maxdepth 1 -type f -name '*.rpm' 2>/dev/null | wc -l | tr -d ' ')"
    if (( count == 0 )); then
        echo "NOTE: none found"
        return 0
    fi
    find "${TST_RPM_SHARE_DIR}" -maxdepth 1 -type f -name '*.rpm' -delete || { echo "RPM packages in ${TST_RPM_SHARE_DIR} could not be removed"; return 1; }
    write-log "${run_dir}" clean-rpm-output "Removed ${count} RPM packages from ${TST_RPM_SHARE_DIR}"
    echo "NOTE: ${count} removed"
}
