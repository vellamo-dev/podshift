#!/usr/bin/env bash
# @file: 120-networks.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example networks added.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Adds one example network of each source: Quadlet, user service and unmanaged.
# @details:
#   Installs the .network files into PODSHIFT_PODMAN_QUADLETS_DIR and the .service files into
#   ~/.config/systemd/user of the podshift user, runs daemon-reload, starts the Quadlet network
#   units, enables and starts the services, then creates each network in unmanaged.list that does
#   not exist yet. Existing files are replaced and existing networks are kept, so it can run again.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was added, or the problem.
# @exitcode: 0 if all were added, 1 on an error, 3 if the VM is not running.
networks() {
    local run_dir vm dir file base name opts line count
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/networks"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    count=0
    for file in "${dir}"/example-*.network; do
        [[ -f "${file}" ]] || continue
        vm-podshift-install-file "${vm}" "${file}" /home/podshift/.config/containers/systemd || return 1
        count=$((count + 1))
    done
    for file in "${dir}"/example-*.service; do
        [[ -f "${file}" ]] || continue
        vm-podshift-install-file "${vm}" "${file}" /home/podshift/.config/systemd/user || return 1
        count=$((count + 1))
    done
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    for file in "${dir}"/example-*.network; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}" .network)"
        if ! vm-podshift-systemctl "${vm}" start "${base}-network.service"; then
            write-log "${run_dir}" postinstall-examples "start ${base}-network.service failed"
            echo "Could not start ${base}-network.service"
            return 1
        fi
    done
    for file in "${dir}"/example-*.service; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}")"
        if ! vm-podshift-systemctl "${vm}" enable --now "${base}"; then
            write-log "${run_dir}" postinstall-examples "enable --now ${base} failed"
            echo "Could not enable and start ${base}"
            return 1
        fi
    done
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        opts=""
        [[ "${line}" == *" "* ]] && opts="${line#* }"
        if vm-podshift-run "${vm}" podman network exists "${name}"; then
            continue
        fi
        # shellcheck disable=SC2086
        if ! vm-podshift-run "${vm}" podman network create ${opts} "${name}" >/dev/null; then
            write-log "${run_dir}" postinstall-examples "podman network create ${name} failed"
            echo "Could not create the network ${name}"
            return 1
        fi
        count=$((count + 1))
    done <<< "$(example-network-lines "${dir}/unmanaged.list")"
    write-log "${run_dir}" postinstall-examples "example networks in place, ${count} files or networks added or replaced"
    echo "NOTE: example networks in place"
    return 0
}
