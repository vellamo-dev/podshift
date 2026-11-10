#!/usr/bin/env bash
# @file: 520-verify-installer-base.sh
# @source-dir: src/test/cli/tests/install-image/os-specific/mac/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM base.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the Lima base VM (TST_RPM_INSTALLER_BASE) exists and is stopped, so it can be cloned.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if it exists and is stopped, 1 otherwise.
verify-installer-base() {
    local run_dir base
    run_dir="${1}"
    base="${TST_RPM_INSTALLER_BASE}"
    if ! vm-exists "${base}"; then
        write-log "${run_dir}" install-image "Base ${base}: missing"
        echo "The base VM ${base} does not exist"
        return 1
    fi
    if vm-running "${base}"; then
        write-log "${run_dir}" install-image "Base ${base}: running"
        echo "The base VM ${base} is running, so it cannot be cloned"
        return 1
    fi
    write-log "${run_dir}" install-image "Base ${base}: present, stopped"
}
