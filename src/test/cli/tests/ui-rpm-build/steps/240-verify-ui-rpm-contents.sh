#!/usr/bin/env bash
# @file: 240-verify-ui-rpm-contents.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Verify cockpit-podshift RPM contents.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM has the Cockpit files and the metainfo, and does not require podshift.
# @arg: $1 - the run folder.
# @stdout: the problems, if any, or NOTE skipped.
# @exitcode: 0 if all checks passed or skipped, 2 otherwise.
verify-ui-rpm-contents() {
    local run_dir rpm_file rc
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    rpm_file="/builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm"
    rc=0
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "manifest.json in RPM" "rpm -qlp ${rpm_file} | grep -qx /usr/share/cockpit/podshift/manifest.json" || rc=2
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "index.js in RPM" "rpm -qlp ${rpm_file} | grep -qx /usr/share/cockpit/podshift/index.js" || rc=2
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "metainfo in RPM" "rpm -qlp ${rpm_file} | grep -qx /usr/share/metainfo/fyi.vellamo.cockpit_podshift.metainfo.xml" || rc=2
    run-check-in-ui-builder "${run_dir}" ui-rpm-build 2 "no podshift dependency" "rpm -qpR ${rpm_file} >/dev/null && ! rpm -qpR ${rpm_file} | grep -Eq '^podshift([[:space:]]|\$)'" || rc=2
    return "${rc}"
}
