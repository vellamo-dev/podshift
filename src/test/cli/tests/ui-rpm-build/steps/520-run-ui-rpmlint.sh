#!/usr/bin/env bash
# @file: 520-run-ui-rpmlint.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Run rpmlint on cockpit-podshift RPMs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs rpmlint on the spec, RPM and source RPM as a warning only.
# @details:
#   The full output goes to ui-rpmlint.log in the run folder. Findings never fail the test.
# @arg: $1 - the run folder.
# @stdout: NOTE with the rpmlint summary, not available, or skipped.
# @exitcode: always 0.
run-ui-rpmlint() {
    local run_dir out_file summary
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    if ! container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c 'command -v rpmlint' >/dev/null 2>&1; then
        write-log "${run_dir}" ui-rpm-build "rpmlint: not available, skipped"
        echo "NOTE: rpmlint not available, skipped"
        return 0
    fi
    out_file="${run_dir}/ui-rpmlint.log"
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c 'rpmlint /builder/output/SOURCES/cockpit-podshift.spec /builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm /builder/output/SRPMS/cockpit-podshift-*.src.rpm' >"${out_file}" 2>&1
    summary="$(grep -E '[0-9]+ errors?, [0-9]+ warnings?' "${out_file}" | tail -n 1 | sed -E 's/.*checked; //; s/\.$//')"
    write-log "${run_dir}" ui-rpm-build "rpmlint: ${summary:-done}, see ui-rpmlint.log"
    echo "NOTE: rpmlint ${summary:-done}, see ui-rpmlint.log"
    return 0
}
