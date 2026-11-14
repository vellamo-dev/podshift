#!/usr/bin/env bash
# @file: 230-verify-ui-rpm-version.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Verify cockpit-podshift RPM name and version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM has the name, version and release that the cockpit-podshift spec defines.
# @arg: $1 - the run folder.
# @stdout: NOTE with the package name, the problem, or NOTE skipped.
# @exitcode: 0 if they match or skipped, 2 otherwise.
verify-ui-rpm-version() {
    local run_dir fmt from_spec from_rpm
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    fmt='%{name}-%{version}-%{release}'
    from_spec="$(container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" rpmspec -q --srpm --qf "${fmt}" /builder/output/SOURCES/cockpit-podshift.spec 2>/dev/null)"
    from_rpm="$(container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c "rpm -qp --qf '${fmt}' /builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm" 2>/dev/null)"
    write-log "${run_dir}" ui-rpm-build "Spec version: ${from_spec:-unknown}"
    write-log "${run_dir}" ui-rpm-build "RPM version: ${from_rpm:-unknown}"
    if [[ -z "${from_spec}" || "${from_spec}" != "${from_rpm}" ]]; then
        echo "The RPM is ${from_rpm:-unknown}, but the spec file says ${from_spec:-unknown}"
        return 2
    fi
    echo "NOTE: ${from_rpm}"
}
