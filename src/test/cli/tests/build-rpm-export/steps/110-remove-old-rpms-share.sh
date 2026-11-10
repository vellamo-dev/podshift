#!/usr/bin/env bash
# @file: 110-remove-old-rpms-share.sh
# @source-dir: src/test/cli/tests/build-rpm-export/steps
# @group: test
# @category: step
# @description: Remove old RPM packages.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the old .rpm files from the share folder.
# @details:
#   Other files there are left alone.
# @arg: $1 - the run folder.
# @stdout: NOTE with how many were removed, or none found.
# @exitcode: 0 if no old RPM is left, 1 otherwise.
remove-old-rpms-share() {
    local run_dir old count
    run_dir="${1}"
    old="$(find "${TST_RPM_SHARE_DIR}" -maxdepth 1 -type f -name '*.rpm' 2>/dev/null)"
    if [[ -z "${old}" ]]; then
        echo "NOTE: none found"
        return 0
    fi
    count="$(printf '%s\n' "${old}" | wc -l | tr -d ' ')"
    find "${TST_RPM_SHARE_DIR}" -maxdepth 1 -type f -name '*.rpm' -delete || { echo "Old RPM packages in ${TST_RPM_SHARE_DIR} could not be removed"; return 1; }
    printf '%s\n' "${old}" | while IFS= read -r file; do write-log "${run_dir}" build-rpm-export "Removed: ${file}"; done
    echo "NOTE: removed ${count}"
}
