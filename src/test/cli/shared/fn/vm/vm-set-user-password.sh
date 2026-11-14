#!/usr/bin/env bash
# @file: vm-set-user-password.sh
# @source-dir: src/test/cli/shared/fn/vm
# @group: test
# @category: helper
# @description: Sets the installer VM login user's password from RPM_VM_USER_PSW.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Sets the installer VM login user's password from RPM_VM_USER_PSW, or skips if it is empty.
# @details:
#   The login user is the current user on this computer, when that account exists in the VM. The
#   password comes from the environment or the local .env file, which run.sh loads at start, so
#   nothing is asked. It is piped to chpasswd on stdin and is never written to the logs, the
#   command line, or xtrace. passwd -S checks that it was set, without printing it. Running it
#   again only sets the same password again.
# @arg: $1 - the run folder.
# @arg: $2 - the log name, usually the test name.
# @arg: $3 - what to do when the user is not in the VM: fail or skip.
# @stdout: NOTE if the password was set or skipped, or the problem if any.
# @exitcode: 0 if set or skipped, 1 otherwise.
vm-set-user-password() {
    local run_dir log_name missing vm user status state rc xtrace_on=0
    [[ "${-}" == *x* ]] && xtrace_on=1
    set +x
    run_dir="${1}"
    log_name="${2}"
    missing="${3:-fail}"
    vm="${TST_RPM_INSTALLER_VM}"
    user="$(id -un)"
    rc=0
    if [[ -z "${RPM_VM_USER_PSW:-}" ]]; then
        write-log "${run_dir}" "${log_name}" "RPM_VM_USER_PSW not set, skipped"
        echo "NOTE: RPM_VM_USER_PSW not set, skipped"
    elif ! vm-run "${vm}" getent passwd "${user}" >/dev/null 2>&1; then
        write-log "${run_dir}" "${log_name}" "user ${user} not in the VM"
        if [[ "${missing}" == "skip" ]]; then
            echo "NOTE: user ${user} not in the VM, skipped"
        else
            echo "The user ${user} does not exist in ${vm}"
            rc=1
        fi
    elif ! printf '%s:%s\n' "${user}" "${RPM_VM_USER_PSW}" | vm-run-stdin "${vm}" chpasswd; then
        write-log "${run_dir}" "${log_name}" "chpasswd failed for ${user}"
        echo "Could not set the password for ${user} in ${vm}"
        rc=1
    elif ! status="$(vm-run "${vm}" passwd -S "${user}")"; then
        write-log "${run_dir}" "${log_name}" "passwd -S ${user} failed"
        echo "Could not check the password status for ${user} in ${vm}"
        rc=1
    else
        state="$(awk '{print $2}' <<<"${status}")"
        if [[ "${state}" != "PS" && "${state}" != "P" ]]; then
            write-log "${run_dir}" "${log_name}" "passwd -S ${user}: ${status}"
            echo "The password for ${user} was not set (passwd status ${state:-unknown})"
            rc=1
        else
            write-log "${run_dir}" "${log_name}" "password set for ${user}, passwd status ${state}"
            echo "NOTE: password set for ${user}"
        fi
    fi
    [[ "${xtrace_on}" -eq 1 ]] && set -x
    return "${rc}"
}
