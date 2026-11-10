#!/usr/bin/env bash
# @file: 510-verify-rpm-package-file.sh
# @source-dir: src/test/cli/tests/install-rpm-check/steps
# @group: test
# @category: step
# @description: Verify RPM package file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM in the share folder starts with the RPM file signature.
# @arg: $1 - the run folder.
# @stdout: the problem and a fix, if any.
# @exitcode: 0 if it looks like an RPM, 3 otherwise.
verify-rpm-package-file() {
    local run_dir file magic
    run_dir="${1}"
    file="$(find-exported-rpm "${TST_RPM_SHARE_DIR}" 2>&1)" || { echo "${file}"; return 3; }
    magic="$(od -An -tx1 -N4 "${file}" 2>/dev/null | tr -d ' \n')"
    if [[ "${magic}" != "edabeedb" ]]; then
        write-log "${run_dir}" install-rpm-check "Check ${file##*/} is an RPM: failed"
        echo "${file##*/} is not a valid RPM file"
        echo "Fix: run build-rpm-export to build a fresh one"
        return 3
    fi
    write-log "${run_dir}" install-rpm-check "Check ${file##*/} is an RPM: ok"
}
