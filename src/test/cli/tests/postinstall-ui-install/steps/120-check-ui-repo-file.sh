#!/usr/bin/env bash
# @file: 120-check-ui-repo-file.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Check cockpit-podshift repo file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the podshift RPM put the cockpit-podshift COPR repo file in the VM.
# @arg: $1 - the run folder.
# @stdout: NOTE present or skipped, or the problem.
# @exitcode: 0 if present or skipped, 2 if missing (PodShift problem).
check-ui-repo-file() {
    local run_dir repo
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    repo=/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:vellamo:cockpit-podshift.repo
    if ! vm-run "${TST_RPM_INSTALLER_VM}" test -f "${repo}"; then
        write-log "${run_dir}" postinstall-ui-install "Repo file ${repo}: missing"
        echo "The repo file ${repo} is missing in the VM"
        echo "Fix: check that the podshift RPM ships it, then ./test bundle-build-install-validate"
        return 2
    fi
    write-log "${run_dir}" postinstall-ui-install "Repo file ${repo}: present"
    echo "NOTE: present"
}
