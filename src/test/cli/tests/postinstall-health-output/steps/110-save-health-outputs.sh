#!/usr/bin/env bash
# @file: 110-save-health-outputs.sh
# @source-dir: src/test/cli/tests/postinstall-health-output/steps
# @group: test
# @category: step
# @description: Run health check in every mode.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs podshift health-check as root in the installer VM in every output mode and saves each output.
# @details:
#   The modes are a terminal, plain, --tsv and --json. Each output is saved in the run folder.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if all four ran, 2 if one did not (PodShift problem), 3 if the VM is not running.
save-health-outputs() {
    local run_dir rc_tty rc_plain rc_tsv rc_json
    run_dir="${1}"
    if ! vm-running "${TST_RPM_INSTALLER_VM}"; then
        echo "The VM ${TST_RPM_INSTALLER_VM} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    vm-run-tty "${TST_RPM_INSTALLER_VM}" podshift health-check >"${run_dir}/health-output-tty.log" 2>&1
    rc_tty=$?
    vm-run "${TST_RPM_INSTALLER_VM}" podshift --plain health-check >"${run_dir}/health-output-plain.log" 2>&1
    rc_plain=$?
    vm-run "${TST_RPM_INSTALLER_VM}" podshift health-check --tsv >"${run_dir}/health-output.tsv" 2>&1
    rc_tsv=$?
    vm-run "${TST_RPM_INSTALLER_VM}" podshift health-check --json >"${run_dir}/health-output.json" 2>&1
    rc_json=$?
    write-log "${run_dir}" postinstall-health-output "Health check exit codes: terminal ${rc_tty}, plain ${rc_plain}, tsv ${rc_tsv}, json ${rc_json}"
    [[ "${rc_tty}${rc_plain}${rc_tsv}${rc_json}" == "0000" ]] && return 0
    echo "podshift health-check did not run in every mode (terminal ${rc_tty}, plain ${rc_plain}, tsv ${rc_tsv}, json ${rc_json})"
    return 2
}
