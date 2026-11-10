#!/usr/bin/env bash
# @file: 520-verify-nothing-left.sh
# @source-dir: src/test/cli/tests/clean-all/steps
# @group: test
# @category: step
# @description: Verify nothing left.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM builder container, test images, RPM packages, temporary and work files and logs are gone.
# @details:
#   The temporary files are those in artifacts/tmp, the work files those in artifacts/work.
#   Only this run's own empty folder may be left in artifacts/logs, and it is removed at the end.
# @arg: $1 - the run folder.
# @stdout: a DETAIL line for each thing still left.
# @exitcode: 0 if nothing is left, 1 otherwise.
verify-nothing-left() {
    local run_dir left name image
    run_dir="${1}"
    left=0
    if container-cli inspect "${TST_RPM_BUILDER_CNT}" >/dev/null 2>&1; then
        echo "DETAIL: container ${TST_RPM_BUILDER_CNT}"
        left=$((left + 1))
    fi
    for name in "${TST_RPM_BUILDER_IMG}" "${TST_RPM_INSTALLER_IMG}"; do
        for image in $(image-tags "${name}"); do
            echo "DETAIL: image ${image}"
            left=$((left + 1))
        done
    done
    for name in $(find "${TST_RPM_SHARE_DIR}" -maxdepth 1 -type f -name '*.rpm' 2>/dev/null); do
        echo "DETAIL: RPM ${name}"
        left=$((left + 1))
    done
    for name in $(find artifacts/tmp -mindepth 1 -maxdepth 1 2>/dev/null); do
        echo "DETAIL: temporary ${name}"
        left=$((left + 1))
    done
    for name in $(find artifacts/work -mindepth 1 -maxdepth 1 2>/dev/null); do
        echo "DETAIL: work ${name}"
        left=$((left + 1))
    done
    for name in $(find artifacts/logs -mindepth 1 -maxdepth 1 2>/dev/null); do
        [[ "$(basename "${name}")" != "$(basename "${run_dir}")" ]] || continue
        echo "DETAIL: log ${name}"
        left=$((left + 1))
    done
    if (( left > 0 )); then
        echo "NOTE: ${left} left"
        return 1
    fi
    rmdir "${run_dir}" 2>/dev/null || true
}
