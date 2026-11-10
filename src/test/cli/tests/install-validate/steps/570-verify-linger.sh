#!/usr/bin/env bash
# @file: 570-verify-linger.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify linger.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that lingering is enabled for the podshift user, so its services run without a login.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if enabled, 2 otherwise.
verify-linger() {
    local run_dir
    run_dir="${1}"
    if vm-run "${TST_RPM_INSTALLER_VM}" test -f /var/lib/systemd/linger/podshift; then
        write-log "${run_dir}" install-validate "Check linger: enabled"
        return 0
    fi
    write-log "${run_dir}" install-validate "Check linger: not enabled"
    echo "Linger is not enabled for podshift (no /var/lib/systemd/linger/podshift)"
    return 2
}
