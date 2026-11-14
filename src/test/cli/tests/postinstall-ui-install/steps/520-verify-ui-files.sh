#!/usr/bin/env bash
# @file: 520-verify-ui-files.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Verify cockpit-podshift files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that manifest.json and the metainfo file are installed in the VM.
# @arg: $1 - the run folder.
# @stdout: the problems, if any, or NOTE skipped.
# @exitcode: 0 if all are there or skipped, 2 otherwise.
verify-ui-files() {
    local run_dir path rc
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    rc=0
    for path in /usr/share/cockpit/podshift/manifest.json /usr/share/metainfo/fyi.vellamo.cockpit_podshift.metainfo.xml; do
        if vm-run "${TST_RPM_INSTALLER_VM}" test -f "${path}"; then
            write-log "${run_dir}" postinstall-ui-install "Check ${path}: ok"
        else
            write-log "${run_dir}" postinstall-ui-install "Check ${path}: failed"
            echo "${path} is missing"
            rc=2
        fi
    done
    return "${rc}"
}
