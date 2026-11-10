#!/usr/bin/env bash
# @file: 120-copy-rpm-to-share.sh
# @source-dir: src/test/cli/tests/build-rpm-export/steps
# @group: test
# @category: step
# @description: Copy RPM package to share folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies the binary RPM from the RPM builder container to /share, which is the share folder on the host.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file name, or the problem.
# @exitcode: 0 if copied, 1 otherwise.
copy-rpm-to-share() {
    local run_dir rpm_name
    run_dir="${1}"
    rpm_name="$(container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash -c 'basename /builder/output/RPMS/noarch/podshift-*.noarch.rpm' 2>/dev/null)"
    container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" cp "/builder/output/RPMS/noarch/${rpm_name}" /share/ || { echo "The RPM package could not be copied to /share"; return 1; }
    write-log "${run_dir}" build-rpm-export "Copied: ${TST_RPM_SHARE_DIR}/${rpm_name}"
    echo "NOTE: ${rpm_name}"
}
