#!/usr/bin/env bash
# @file: 110-find-rpm-package.sh
# @source-dir: src/test/cli/tests/install-rpm-check/steps
# @group: test
# @category: step
# @description: Find RPM package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Finds the one binary RPM in the share folder.
# @details:
#   If there is none or more than one, the rest of the test does not run.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file name and age, or the problem and a fix.
# @exitcode: 0 if found, 3 if there is none or more than one.
find-rpm-package() {
    local run_dir file shown
    run_dir="${1}"
    if ! file="$(find-exported-rpm "${TST_RPM_SHARE_DIR}" 2>&1)"; then
        write-log "${run_dir}" install-rpm-check "Check RPM in ${TST_RPM_SHARE_DIR}: ${file}"
        echo "${file}"
        echo "Fix: run build-rpm-export to build one, or leave exactly one RPM in ${TST_RPM_SHARE_DIR}"
        return 3
    fi
    shown="$(format-age "$(file-age "${file}")")"
    write-log "${run_dir}" install-rpm-check "Check RPM in ${TST_RPM_SHARE_DIR}: ${file##*/}, ${shown} old"
    echo "NOTE: ${file##*/}, ${shown} old"
}
