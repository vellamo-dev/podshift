#!/usr/bin/env bash
# @file: find-ui-rpm.sh
# @source-dir: src/test/cli/shared/fn/rpm
# @group: test
# @category: helper
# @description: Finds the newest exported cockpit-podshift RPM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the path of the newest cockpit-podshift-*.noarch.rpm in TST_UI_RPM_SHARE_DIR.
# @details:
#   Source RPMs are ignored. ui-rpm-build exports the RPM there.
# @stdout: the path.
# @stderr: the problem, if there is none.
# @exitcode: 0 if one was found, 1 otherwise.
find-ui-rpm() {
    local file
    file="$(ls -t "${TST_UI_RPM_SHARE_DIR}"/cockpit-podshift-*.noarch.rpm 2>/dev/null | head -n 1)"
    if [[ -z "${file}" || ! -s "${file}" ]]; then
        echo "No cockpit-podshift-*.noarch.rpm in ${TST_UI_RPM_SHARE_DIR}" >&2
        return 1
    fi
    printf '%s\n' "${file}"
}
