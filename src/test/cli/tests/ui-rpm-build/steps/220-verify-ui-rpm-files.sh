#!/usr/bin/env bash
# @file: 220-verify-ui-rpm-files.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Verify cockpit-podshift RPM files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that rpmbuild made one noarch RPM and one source RPM, and that the RPM is valid.
# @details:
#   A setup step, so a failed check stops the export.
# @arg: $1 - the run folder.
# @stdout: the problems, if any, or NOTE skipped.
# @exitcode: 0 if all checks passed or skipped, 2 otherwise.
verify-ui-rpm-files() {
    local run_dir rc
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    rc=0
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "one binary RPM built" "test \$(ls /builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm | wc -l) -eq 1" || rc=2
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "one source RPM built" "test \$(ls /builder/output/SRPMS/cockpit-podshift-*.src.rpm | wc -l) -eq 1" || rc=2
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "binary RPM is valid" "rpm -qip /builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm" || rc=2
    return "${rc}"
}
