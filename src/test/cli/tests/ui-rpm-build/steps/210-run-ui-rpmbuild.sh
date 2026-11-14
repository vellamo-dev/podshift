#!/usr/bin/env bash
# @file: 210-run-ui-rpmbuild.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Run rpmbuild for cockpit-podshift.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs rpmbuild -ba on the cockpit-podshift spec inside the builder.
# @details:
#   The full rpmbuild output, with the spec's own %check, goes to ui-rpmbuild.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: the last rpmbuild lines if it failed, or NOTE skipped.
# @exitcode: 0 if the RPMs were built or skipped, 2 otherwise.
run-ui-rpmbuild() {
    local run_dir out_file
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    out_file="${run_dir}/ui-rpmbuild.log"
    if ! container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" rpmbuild -ba /builder/output/SOURCES/cockpit-podshift.spec --define "_topdir /builder/output" >"${out_file}" 2>&1; then
        write-log "${run_dir}" ui-rpm-build "rpmbuild: failed, see ui-rpmbuild.log"
        echo "rpmbuild failed. Last lines of ui-rpmbuild.log:"
        tail -n 15 "${out_file}"
        return 2
    fi
    write-log "${run_dir}" ui-rpm-build "rpmbuild: done, see ui-rpmbuild.log"
    grep '^Wrote: ' "${out_file}" | while IFS= read -r line; do write-log "${run_dir}" ui-rpm-build "${line}"; done
}
