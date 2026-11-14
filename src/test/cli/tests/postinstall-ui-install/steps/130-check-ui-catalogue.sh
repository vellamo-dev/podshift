#!/usr/bin/env bash
# @file: 130-check-ui-catalogue.sh
# @source-dir: src/test/cli/tests/postinstall-ui-install/steps
# @group: test
# @category: step
# @description: Check PodShift UI catalogue entry.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that /usr/share/swcatalog/xml/podshift.xml is in the VM and names the cockpit-podshift package.
# @details:
#   The file is read with cat and searched on the host, because vm-run does not keep shell quoting.
# @arg: $1 - the run folder.
# @stdout: NOTE present or skipped, or the problem.
# @exitcode: 0 if present or skipped, 2 otherwise (PodShift problem).
check-ui-catalogue() {
    local run_dir catalogue content
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    catalogue=/usr/share/swcatalog/xml/podshift.xml
    if ! content="$(vm-run "${TST_RPM_INSTALLER_VM}" cat "${catalogue}" 2>/dev/null)"; then
        write-log "${run_dir}" postinstall-ui-install "Catalogue ${catalogue}: missing"
        echo "The catalogue ${catalogue} is missing in the VM"
        echo "Fix: check that the podshift RPM ships it, then ./test bundle-build-install-validate"
        return 2
    fi
    if ! grep -q '<pkgname>cockpit-podshift</pkgname>' <<<"${content}"; then
        write-log "${run_dir}" postinstall-ui-install "Catalogue ${catalogue}: no <pkgname>cockpit-podshift</pkgname>"
        echo "${catalogue} has no <pkgname>cockpit-podshift</pkgname>"
        return 2
    fi
    write-log "${run_dir}" postinstall-ui-install "Catalogue ${catalogue}: present, names cockpit-podshift"
    echo "NOTE: present"
}
