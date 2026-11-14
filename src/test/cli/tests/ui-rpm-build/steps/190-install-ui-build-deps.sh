#!/usr/bin/env bash
# @file: 190-install-ui-build-deps.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Install cockpit-podshift build dependencies.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Installs the spec's BuildRequires with dnf builddep, and nothing else.
# @details:
#   The full output goes to ui-builddep.log in the run folder. dnf needs network in the container.
# @arg: $1 - the run folder.
# @stdout: the last dnf lines if it failed, or NOTE skipped.
# @exitcode: 0 if installed or skipped, 1 otherwise.
install-ui-build-deps() {
    local run_dir out_file
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    out_file="${run_dir}/ui-builddep.log"
    if ! container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" dnf builddep -y /builder/output/SOURCES/cockpit-podshift.spec >"${out_file}" 2>&1; then
        write-log "${run_dir}" ui-rpm-build "dnf builddep: failed, see ui-builddep.log"
        echo "dnf builddep failed. Last lines of ui-builddep.log:"
        tail -n 15 "${out_file}"
        return 1
    fi
    write-log "${run_dir}" ui-rpm-build "dnf builddep: done, see ui-builddep.log"
}
