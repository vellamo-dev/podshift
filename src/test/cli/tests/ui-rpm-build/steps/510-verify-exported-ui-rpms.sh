#!/usr/bin/env bash
# @file: 510-verify-exported-ui-rpms.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Verify exported cockpit-podshift RPMs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks on the host that the RPM and source RPM are in the share folder and match the built ones.
# @arg: $1 - the run folder.
# @stdout: the problems, if any, or NOTE skipped.
# @exitcode: 0 if verified or skipped, 1 otherwise.
verify-exported-ui-rpms() {
    local run_dir path name host_file host_sum cnt_sum rc
    run_dir="${1}"
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    rc=0
    for path in /builder/output/RPMS/noarch/cockpit-podshift-*.noarch.rpm /builder/output/SRPMS/cockpit-podshift-*.src.rpm; do
        name="$(container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c "basename ${path}" 2>/dev/null)"
        host_file="${TST_UI_RPM_SHARE_DIR}/${name}"
        if [[ -z "${name}" || "${name}" == *'*'* || ! -s "${host_file}" ]]; then
            write-log "${run_dir}" ui-rpm-build "Check ${name:-RPM} in share folder: failed"
            echo "${host_file} is missing or empty"
            rc=1
            continue
        fi
        host_sum="$(cksum <"${host_file}")"
        cnt_sum="$(container-cli exec -u 0 "${TST_UI_RPM_BUILDER_CNT}" bash -c "cksum <${path}" 2>/dev/null)"
        if [[ "${host_sum}" != "${cnt_sum}" ]]; then
            write-log "${run_dir}" ui-rpm-build "Check ${name} matches the built one: failed"
            echo "${host_file} is not the same as the one in the container"
            rc=1
            continue
        fi
        write-log "${run_dir}" ui-rpm-build "Check ${name} in share folder: ok"
    done
    return "${rc}"
}
