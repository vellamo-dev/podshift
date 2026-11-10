#!/usr/bin/env bash
# @file: 510-verify-lima-config.sh
# @source-dir: src/test/cli/tests/install-image/os-specific/mac/steps
# @group: test
# @category: step
# @description: Verify RPM installer VM Lima config.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the Lima config of the RPM installer VM (TST_LIMA_CONFIG) with limactl validate.
# @arg: $1 - the run folder.
# @stdout: the limactl validate output on failure.
# @exitcode: 0 if valid, 1 otherwise.
verify-lima-config() {
    local run_dir file out
    run_dir="${1}"
    file="${TST_LIMA_CONFIG}"
    if out="$(vm validate "${file}" 2>&1)"; then
        write-log "${run_dir}" install-image "Lima config: ${file} valid"
        return 0
    fi
    write-log "${run_dir}" install-image "Lima config: ${file} not valid"
    printf '%s\n' "${out}"
    echo "The Lima config ${file} is not valid"
    return 1
}
