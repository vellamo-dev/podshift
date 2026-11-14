#!/usr/bin/env bash
# @file: 530-check-no-example-images.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: No example images left.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that no example image file, Quadlet container file or labeled container is left for the podshift user.
# @details:
#   Images that the previous step kept because another container still uses them are not counted.
# @arg: $1 - the run folder.
# @stdout: NOTE if nothing is left, or what is left.
# @exitcode: 0 if nothing is left, 2 if something is left, 3 if the VM is not running.
check-no-example-images() {
    local run_dir vm dir file base ctrs
    local -a left
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/images"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    left=()
    for file in "${dir}"/example-*.image "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-run "${vm}" test -e "/home/podshift/.config/containers/systemd/${base}" && left+=("${base}")
    done
    if ! ctrs="$(vm-podshift-run "${vm}" podman ps -a --filter label=podshift.example=1 --format '{{.Names}}')"; then
        echo "Could not list the example containers"
        return 2
    fi
    while IFS= read -r base; do
        [[ -n "${base}" ]] && left+=("container ${base}")
    done <<< "${ctrs}"
    if [[ "${#left[@]}" -gt 0 ]]; then
        write-log "${run_dir}" cleanup-examples "left: ${left[*]}"
        echo "Still there: ${left[*]}"
        echo "Fix: ./test cleanup-examples"
        return 2
    fi
    write-log "${run_dir}" cleanup-examples "no example image files or containers left"
    echo "NOTE: no example image files or containers left"
    return 0
}
