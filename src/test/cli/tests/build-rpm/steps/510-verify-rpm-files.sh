#!/usr/bin/env bash
# @file: 510-verify-rpm-files.sh
# @source-dir: src/test/cli/tests/build-rpm/steps
# @group: test
# @category: step
# @description: Verify RPM files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that rpmbuild made exactly one binary RPM and one source RPM, and that the binary RPM is a valid package.
# @arg: $1 - the run folder.
# @stdout: the problems, if any.
# @exitcode: 0 if all checks passed, 2 otherwise.
verify-rpm-files() {
    local run_dir rc
    run_dir="${1}"
    rc=0
    run-check-in-builder "${run_dir}" build-rpm 2 "one binary RPM built" "test \$(ls /builder/output/RPMS/noarch/podshift-*.noarch.rpm | wc -l) -eq 1" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "one source RPM built" "test \$(ls /builder/output/SRPMS/podshift-*.src.rpm | wc -l) -eq 1" || rc=2
    run-check-in-builder "${run_dir}" build-rpm 2 "binary RPM is valid" "rpm -qip /builder/output/RPMS/noarch/podshift-*.noarch.rpm" || rc=2
    return "${rc}"
}
