#!/usr/bin/env bash
# @file: 110-run-rpmbuild.sh
# @source-dir: src/test/cli/tests/build-rpm/steps
# @group: test
# @category: step
# @description: Run rpmbuild.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs rpmbuild inside the RPM builder container.
# @details:
#   The full rpmbuild output goes to rpmbuild.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: the last rpmbuild lines, if it failed.
# @exitcode: 0 if the RPM was built, 2 otherwise.
run-rpmbuild() {
    local run_dir out_file
    run_dir="${1}"
    out_file="${run_dir}/rpmbuild.log"
    if ! container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" rpmbuild -ba /builder/output/SOURCES/podshift.spec --define "_topdir /builder/output" >"${out_file}" 2>&1; then
        write-log "${run_dir}" build-rpm "rpmbuild: failed, see rpmbuild.log"
        echo "rpmbuild failed. Last lines of rpmbuild.log:"
        tail -n 15 "${out_file}"
        return 2
    fi
    write-log "${run_dir}" build-rpm "rpmbuild: done, see rpmbuild.log"
    grep '^Wrote: ' "${out_file}" | while IFS= read -r line; do write-log "${run_dir}" build-rpm "${line}"; done
}
