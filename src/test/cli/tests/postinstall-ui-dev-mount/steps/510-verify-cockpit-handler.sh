#!/usr/bin/env bash
# @file: 510-verify-cockpit-handler.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount/steps
# @group: test
# @category: step
# @description: Verify the Cockpit handler.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the PodShift Cockpit handler exists in the installer VM.
# @arg: $1 - the run folder.
# @stdout: NOTE with the handler path, or the problem and how to fix it.
# @exitcode: 0 if the handler exists, 2 if it is missing (PodShift problem), 3 if the VM is not running.
verify-cockpit-handler() {
    local run_dir
    run_dir="${1}"
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
        echo "Fix: ./test bundle-ui-dev-mount"
        return 3
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" test -f /opt/podshift/cockpit/api/main.sh; then
        write-log "${run_dir}" postinstall-ui-dev-mount "handler /opt/podshift/cockpit/api/main.sh: missing"
        echo "The handler /opt/podshift/cockpit/api/main.sh is missing"
        echo "Fix: ./test bundle-ui-dev-mount"
        return 2
    fi
    write-log "${run_dir}" postinstall-ui-dev-mount "handler /opt/podshift/cockpit/api/main.sh: present"
    echo "NOTE: /opt/podshift/cockpit/api/main.sh"
}
