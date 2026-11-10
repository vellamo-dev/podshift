#!/usr/bin/env bash
# @file: 530-verify-config.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify config files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the PodShift config files exist and are not empty.
# @arg: $1 - the run folder.
# @stdout: the missing files, if any.
# @exitcode: 0 if all are there, 2 otherwise.
verify-config() {
    local run_dir path missing
    run_dir="${1}"
    missing=0
    for path in \
        /opt/podshift/conf/main.conf \
        /opt/podshift/conf/rootless.conf \
        /usr/lib/tmpfiles.d/podshift-dirs.conf; do
        vm-run "${TST_RPM_INSTALLER_VM}" test -s "${path}" && continue
        echo "Missing or empty: ${path}"
        missing=$((missing + 1))
    done
    write-log "${run_dir}" install-validate "Check config files: ${missing} missing"
    (( missing == 0 )) || return 2
}
