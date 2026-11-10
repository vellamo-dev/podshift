#!/usr/bin/env bash
# @file: 520-verify-rpm-version.sh
# @source-dir: src/test/cli/tests/build-rpm/steps
# @group: test
# @category: step
# @description: Verify RPM name and version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the binary RPM has the name, version and release that the spec file defines.
# @arg: $1 - the run folder.
# @stdout: NOTE with the package name, or the problem.
# @exitcode: 0 if they match, 2 otherwise.
verify-rpm-version() {
    local run_dir fmt from_spec from_rpm
    run_dir="${1}"
    fmt='%{name}-%{version}-%{release}'
    from_spec="$(container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" rpmspec -q --srpm --qf "${fmt}" /builder/output/SOURCES/podshift.spec 2>/dev/null)"
    from_rpm="$(container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash -c "rpm -qp --qf '${fmt}' /builder/output/RPMS/noarch/podshift-*.noarch.rpm" 2>/dev/null)"
    write-log "${run_dir}" build-rpm "Spec version: ${from_spec:-unknown}"
    write-log "${run_dir}" build-rpm "RPM version: ${from_rpm:-unknown}"
    if [[ -z "${from_spec}" || "${from_spec}" != "${from_rpm}" ]]; then
        echo "The RPM is ${from_rpm:-unknown}, but the spec file says ${from_spec:-unknown}"
        return 2
    fi
    echo "NOTE: ${from_rpm}"
}
