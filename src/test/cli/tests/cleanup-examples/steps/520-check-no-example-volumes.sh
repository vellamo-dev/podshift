#!/usr/bin/env bash
# @file: 520-check-no-example-volumes.sh
# @source-dir: src/test/cli/tests/cleanup-examples/steps
# @group: test
# @category: step
# @description: No example volumes left.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that no example volume, volume file or volume container file is left for the podshift user.
# @arg: $1 - the run folder.
# @stdout: NOTE if nothing is left, or what is left.
# @exitcode: 0 if nothing is left, 2 if something is left, 3 if the VM is not running.
check-no-example-volumes() {
    local run_dir vm dir file base vols
    local -a left
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/volumes"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        return 3
    fi
    left=()
    for file in "${dir}"/example-*.volume "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        vm-run "${vm}" test -e "/home/podshift/.config/containers/systemd/${base}" && left+=("${base}")
    done
    if ! vols="$(vm-podshift-run "${vm}" podman volume ls --filter label=podshift.example=1 --format '{{.Name}}')"; then
        echo "Could not list the example volumes"
        return 2
    fi
    while IFS= read -r base; do
        [[ -n "${base}" ]] && left+=("volume ${base}")
    done <<< "${vols}"
    if [[ "${#left[@]}" -gt 0 ]]; then
        write-log "${run_dir}" cleanup-examples "left: ${left[*]}"
        echo "Still there: ${left[*]}"
        echo "Fix: ./test cleanup-examples"
        return 2
    fi
    write-log "${run_dir}" cleanup-examples "no example volumes or files left"
    echo "NOTE: no example volumes or files left"
    return 0
}
