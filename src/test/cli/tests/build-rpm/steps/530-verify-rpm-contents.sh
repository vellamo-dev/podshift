#!/usr/bin/env bash
# @file: 530-verify-rpm-contents.sh
# @source-dir: src/test/cli/tests/build-rpm/steps
# @group: test
# @category: step
# @description: Verify RPM contents.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the binary RPM has the PodShift files, the license and the install scripts.
# @arg: $1 - the run folder.
# @stdout: the problems, if any.
# @exitcode: 0 if all checks passed, 2 otherwise.
verify-rpm-contents() {
    local run_dir rpm_file rc
    run_dir="${1}"
    rpm_file="/builder/output/RPMS/noarch/podshift-*.noarch.rpm"
    rc=0
    run-check-in-builder "${run_dir}" build-rpm 2 "files in /opt/podshift" "rpm -qlp ${rpm_file} | grep -q '^/opt/podshift/'" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "post.sh in RPM" "rpm -qlp ${rpm_file} | grep -qx /opt/podshift/rpm/post.sh" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "preun.sh in RPM" "rpm -qlp ${rpm_file} | grep -qx /opt/podshift/rpm/preun.sh" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "posttrans.sh in RPM" "rpm -qlp ${rpm_file} | grep -qx /opt/podshift/rpm/posttrans.sh" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "license in RPM" "rpm -qlp ${rpm_file} | grep -q '/LICENSE\$'" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "post script in RPM" "rpm -qp --scripts ${rpm_file} | grep -q '^postinstall scriptlet'" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "preun script in RPM" "rpm -qp --scripts ${rpm_file} | grep -q '^preuninstall scriptlet'" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "postun script in RPM" "rpm -qp --scripts ${rpm_file} | grep -q '^postuninstall scriptlet'" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "posttrans script in RPM" "rpm -qp --scripts ${rpm_file} | grep -q '^posttrans scriptlet'" || rc=2
    return "${rc}"
}
