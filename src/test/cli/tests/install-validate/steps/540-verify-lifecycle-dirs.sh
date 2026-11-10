#!/usr/bin/env bash
# @file: 540-verify-lifecycle-dirs.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify lifecycle folders.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the podshift user's drop, trash and quadlet folders exist.
# @arg: $1 - the run folder.
# @stdout: the missing folders, if any.
# @exitcode: 0 if all are there, 2 otherwise.
verify-lifecycle-dirs() {
    local run_dir path missing
    run_dir="${1}"
    missing=0
    for path in \
        /home/podshift/drop \
        /home/podshift/trash \
        /home/podshift/.quadlets/validation-queue \
        /home/podshift/.quadlets/source \
        /home/podshift/.quadlets/rejected \
        /home/podshift/.quadlets/staging \
        /home/podshift/.quadlets/installed-backup \
        /home/podshift/.quadlets/failed; do
        vm-run "${TST_RPM_INSTALLER_VM}" test -d "${path}" && continue
        echo "Missing: ${path}"
        missing=$((missing + 1))
    done
    write-log "${run_dir}" install-validate "Check lifecycle folders: ${missing} missing"
    (( missing == 0 )) || return 2
}
