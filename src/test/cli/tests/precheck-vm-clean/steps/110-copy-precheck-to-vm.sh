#!/usr/bin/env bash
# @file: 110-copy-precheck-to-vm.sh
# @source-dir: src/test/cli/tests/precheck-vm-clean/steps
# @group: test
# @category: step
# @description: Copy precheck into VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the precheck settings, then copies utils/portable/precheck.sh into TST_PRECHECK_VM_DIR in the VM.
# @details:
#   The folder and the file are readable by every user, so the check can also run as a normal user
#   when TST_PRECHECK_AS_ROOT is false.
# @arg: $1 - the run folder.
# @stdout: NOTE with the path in the VM, or the problem and a Fix line.
# @exitcode: 0 if copied, 1 if a setting is wrong or the copy failed, 3 if the VM is not running.
copy-precheck-to-vm() {
    local run_dir script vm dir
    run_dir="${1}"
    script="utils/portable/precheck.sh"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_PRECHECK_VM_DIR}"
    case "${TST_PRECHECK_MODE}" in
        plain | json | both) ;;
        *)
            echo "TST_PRECHECK_MODE is '${TST_PRECHECK_MODE}', expected plain, json or both"
            return 1
            ;;
    esac
    case "${TST_PRECHECK_AS_ROOT}" in
        true | false) ;;
        *)
            echo "TST_PRECHECK_AS_ROOT is '${TST_PRECHECK_AS_ROOT}', expected true or false"
            return 1
            ;;
    esac
    if [[ ! -f "${script}" ]]; then
        echo "${script} was not found"
        return 1
    fi
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test precheck-vm-clean"
        return 3
    fi
    if ! vm-run "${vm}" mkdir -p -m 0755 "${dir}" || ! vm-copy "${vm}" "${script}" "${dir}" \
        || ! vm-run "${vm}" chmod 0644 "${dir}/precheck.sh"; then
        write-log "${run_dir}" precheck-vm-clean "Copy ${script} to ${vm}:${dir}: failed"
        echo "${script} could not be copied into ${vm}:${dir}"
        return 1
    fi
    write-log "${run_dir}" precheck-vm-clean "Copy ${script} to ${vm}:${dir}: ok, mode ${TST_PRECHECK_MODE}, as root ${TST_PRECHECK_AS_ROOT}"
    echo "NOTE: ${dir}/precheck.sh"
}
