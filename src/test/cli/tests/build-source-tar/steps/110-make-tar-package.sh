#!/usr/bin/env bash
# @file: 110-make-tar-package.sh
# @source-dir: src/test/cli/tests/build-source-tar/steps
# @group: test
# @category: step
# @description: Create source tar package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs make-tar-from-source.sh in the RPM builder container.
# @arg: $1 - the run folder.
# @stdout: the script output.
# @exitcode: 0 if the package was made, 1 otherwise.
make-tar-package() {
    local run_dir
    run_dir="${1}"
    container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash "/builder/input/podshift-${TST_SOURCE_BRANCH}/src/test/cli/tests/build-source-tar/scripts/make-tar-from-source.sh" "${TST_SOURCE_BRANCH}" || { echo "The source tar package could not be made"; return 1; }
    write-log "${run_dir}" build-source-tar "Source package: /builder/output/SOURCES/${TST_SOURCE_BRANCH}.tar.gz made"
}
