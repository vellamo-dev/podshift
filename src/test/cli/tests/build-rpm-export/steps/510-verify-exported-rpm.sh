#!/usr/bin/env bash
# @file: 510-verify-exported-rpm.sh
# @source-dir: src/test/cli/tests/build-rpm-export/steps
# @group: test
# @category: step
# @description: Verify exported RPM package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks on the host that the RPM is in the share folder and is the same file as the one in the RPM builder container.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if verified, 1 otherwise.
verify-exported-rpm() {
    local run_dir rpm_name host_file host_sum cnt_sum
    run_dir="${1}"
    rpm_name="$(container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash -c 'basename /builder/output/RPMS/noarch/podshift-*.noarch.rpm' 2>/dev/null)"
    host_file="${TST_RPM_SHARE_DIR}/${rpm_name}"
    if [[ -z "${rpm_name}" || ! -s "${host_file}" ]]; then
        write-log "${run_dir}" build-rpm-export "Check RPM in share folder: failed"
        echo "${host_file} is missing or empty"
        return 1
    fi
    write-log "${run_dir}" build-rpm-export "Check RPM in share folder: ok"
    host_sum="$(cksum <"${host_file}")"
    cnt_sum="$(container-cli exec -u 0 "${TST_RPM_BUILDER_CNT}" bash -c "cksum </builder/output/RPMS/noarch/${rpm_name}" 2>/dev/null)"
    if [[ "${host_sum}" != "${cnt_sum}" ]]; then
        write-log "${run_dir}" build-rpm-export "Check RPM matches the built one: failed"
        echo "${host_file} is not the same as the RPM in the container"
        return 1
    fi
    write-log "${run_dir}" build-rpm-export "Check RPM matches the built one: ok"
}
