#!/usr/bin/env bash
# @file: 160-set-vm-user-password.sh
# @source-dir: src/test/cli/tests/install-vm-start/steps
# @group: test
# @category: step
# @description: Set the VM user password.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Sets the new VM login user's password from RPM_VM_USER_PSW with vm-set-user-password, or skips.
# @details:
#   Runs after the VM answers over SSH and systemd has started, so the login user exists. It skips
#   when RPM_VM_USER_PSW is empty or the user is not in the VM. The password is never printed.
# @arg: $1 - the run folder.
# @stdout: NOTE if the password was set or the step was skipped, or the problem if any.
# @exitcode: 0 if set or skipped, 1 otherwise.
set-vm-user-password() {
    vm-set-user-password "${1}" install-vm-start skip
}
