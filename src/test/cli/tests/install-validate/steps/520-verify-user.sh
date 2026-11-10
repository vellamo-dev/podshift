#!/usr/bin/env bash
# @file: 520-verify-user.sh
# @source-dir: src/test/cli/tests/install-validate/steps
# @group: test
# @category: step
# @description: Verify podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the podshift user exists with the UID from TST_PODSHIFT_UID.
# @arg: $1 - the run folder.
# @stdout: NOTE with the UID.
# @exitcode: 0 if it matches, 2 otherwise.
verify-user() {
    local run_dir uid
    run_dir="${1}"
    uid="$(vm-run "${TST_RPM_INSTALLER_VM}" id -u podshift 2>/dev/null | tr -d '[:space:]')"
    write-log "${run_dir}" install-validate "Check podshift user: UID ${uid:-none}"
    if [[ "${uid}" != "${TST_PODSHIFT_UID}" ]]; then
        echo "Expected the podshift user with UID ${TST_PODSHIFT_UID}, found ${uid:-no user}"
        return 2
    fi
    echo "NOTE: UID ${uid}"
}
