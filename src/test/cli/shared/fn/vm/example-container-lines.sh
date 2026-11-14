#!/usr/bin/env bash
# @file: example-container-lines.sh
# @source-dir: src/test/cli/shared/fn/vm
# @group: test
# @category: helper
# @description: Lists the example containers and the state each one should have.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the name and expected state of every example container in the example containers folder.
# @details:
#   The ContainerName= of each example-*.container file (running), the --name of the podman run
#   in each example-*.service file (exited, the container runs once), then the name and state of
#   each line of unmanaged.list. Only names that start with example- are printed.
# @arg: $1 - the example containers folder.
# @stdout: one line per container, <name> <state>.
# @exitcode: 0 always.
example-container-lines() {
    local dir file name line state
    dir="${1}"
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        name="$(sed -n 's/^ContainerName=//p' "${file}" | tail -n 1)"
        name="${name:-systemd-$(basename "${file}" .container)}"
        [[ "${name}" == example-* ]] && printf '%s running\n' "${name}"
    done
    for file in "${dir}"/example-*.service; do
        [[ -f "${file}" ]] || continue
        name="$(sed -n 's/^ExecStart=.*podman run .*--name \(example-[A-Za-z0-9_.-]*\).*/\1/p' "${file}" | head -n 1)"
        [[ -n "${name}" ]] && printf '%s exited\n' "${name}"
    done
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        state="${line#* }"
        state="${state%% *}"
        [[ "${state}" == "${name}" ]] && state="running"
        printf '%s %s\n' "${name}" "${state}"
    done <<< "$(example-network-lines "${dir}/unmanaged.list" 2>/dev/null)"
    return 0
}
