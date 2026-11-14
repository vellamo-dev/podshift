#!/usr/bin/env bash
# @file: 310-copy-ui-rpms-to-share.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Copy cockpit-podshift RPMs to share folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes old cockpit-podshift RPMs from the share folder, then copies the new RPM and source RPM there.
# @details:
#   The share folder is TST_UI_RPM_SHARE_DIR, the cockpit-podshift artifacts/rpm by default. Only
#   cockpit-podshift-*.rpm files there are removed; other files are left alone.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file names, the problem, or NOTE skipped.
# @exitcode: 0 if copied or skipped, 1 otherwise.
copy-ui-rpms-to-share() {
    local run_dir old names
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    old="$(find "${TST_UI_RPM_SHARE_DIR}" -maxdepth 1 -type f -name 'cockpit-podshift-*.rpm' 2>/dev/null)"
    if [[ -n "${old}" ]]; then
        find "${TST_UI_RPM_SHARE_DIR}" -maxdepth 1 -type f -name 'cockpit-podshift-*.rpm' -delete || { echo "Old RPMs in ${TST_UI_RPM_SHARE_DIR} could not be removed"; return 1; }
        printf '%s\n' "${old}" | while IFS= read -r file; do write-log "${run_dir}" ui-rpm-build "Removed: ${file}"; done
    fi
    container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c 'cp /builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm /builder/output/SRPMS/cockpit-podshift-*.src.rpm /share/' || { echo "The RPMs could not be copied to /share"; return 1; }
    names="$(container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c 'cd /builder/output && ls RPMS/noarch/cockpit-podshift-*.noarch.rpm SRPMS/cockpit-podshift-*.src.rpm | xargs -n 1 basename' 2>/dev/null)"
    printf '%s\n' "${names}" | while IFS= read -r file; do write-log "${run_dir}" ui-rpm-build "Copied: ${TST_UI_RPM_SHARE_DIR}/${file}"; done
    echo "NOTE: $(printf '%s\n' "${names}" | head -n 1)"
}
