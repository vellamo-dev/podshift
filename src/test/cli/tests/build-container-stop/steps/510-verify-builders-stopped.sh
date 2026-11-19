#!/usr/bin/env bash
# @file: 510-verify-builders-stopped.sh
# @source-dir: src/test/cli/tests/build-container-stop/steps
# @group: test
# @category: step
# @description: Verify RPM builder containers are stopped.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that neither RPM builder container is running, unless TST_KEEP_BUILDERS is true.
# @details:
#   The cockpit-podshift RPM builder is checked only when TST_UI_PRESENT is true, like step 120.
# @arg: $1 - the run folder.
# @stdout: NOTE kept, or the containers that still run.
# @exitcode: 0 if none is running or they are kept, 1 otherwise.
verify-builders-stopped() {
    local run_dir rc
    run_dir="${1}"
    [[ "${TST_KEEP_BUILDERS}" != "true" ]] || { echo "NOTE: kept"; return 0; }
    rc=0
    if container-running "${TST_RPM_BUILDER_CNT}"; then
        echo "The container ${TST_RPM_BUILDER_CNT} is still running"
        rc=1
    fi
    if [[ "${TST_UI_PRESENT}" == "true" ]] && container-running "${TST_UI_RPM_BUILDER_CNT}"; then
        echo "The container ${TST_UI_RPM_BUILDER_CNT} is still running"
        rc=1
    fi
    [[ "${rc}" -ne 0 ]] || write-log "${run_dir}" build-container-stop "Check builders stopped: ok"
    return "${rc}"
}
