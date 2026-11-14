#!/usr/bin/env bash
# @file: 140-volumes.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example volumes added.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Adds one example volume of each source: Quadlet, container and unmanaged.
# @details:
#   Installs the .volume and .container files into PODSHIFT_PODMAN_QUADLETS_DIR of the podshift
#   user. Creates the named volumes of the example containers and each volume in unmanaged.list
#   with podman volume create when missing, so they carry the podshift.example=1 label. Runs
#   daemon-reload, starts the Quadlet volume units (<base>-volume.service) and the container units
#   (<base>.service), then writes a small file into the Quadlet and unmanaged volumes so du shows
#   a size. The example container writes its own file. It can run again.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was added, or the problem.
# @exitcode: 0 if all were added, 1 on an error, 3 if the VM is not running.
volumes() {
    local run_dir vm dir file base name opts line count
    local -a fill
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/volumes"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    count=0
    fill=()
    for file in "${dir}"/example-*.volume "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        vm-podshift-install-file "${vm}" "${file}" /home/podshift/.config/containers/systemd || return 1
        count=$((count + 1))
    done
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        while IFS= read -r name; do
            [[ "${name}" == example-* ]] || continue
            vm-podshift-run "${vm}" podman volume exists "${name}" && continue
            if ! vm-podshift-run "${vm}" podman volume create --label podshift.example=1 "${name}" >/dev/null; then
                write-log "${run_dir}" postinstall-examples "podman volume create ${name} failed"
                echo "Could not create the volume ${name}"
                return 1
            fi
            count=$((count + 1))
        done <<< "$(sed -n 's/^Volume=\([^:/][^:]*\):.*/\1/p' "${file}")"
    done
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        name="${line%% *}"
        opts=""
        [[ "${line}" == *" "* ]] && opts="${line#* }"
        fill+=("${name}")
        vm-podshift-run "${vm}" podman volume exists "${name}" && continue
        # shellcheck disable=SC2086
        if ! vm-podshift-run "${vm}" podman volume create ${opts} "${name}" >/dev/null; then
            write-log "${run_dir}" postinstall-examples "podman volume create ${name} failed"
            echo "Could not create the volume ${name}"
            return 1
        fi
        count=$((count + 1))
    done <<< "$(example-network-lines "${dir}/unmanaged.list")"
    if ! vm-podshift-systemctl "${vm}" daemon-reload; then
        echo "systemctl --user daemon-reload failed for podshift"
        return 1
    fi
    for file in "${dir}"/example-*.volume; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}" .volume)"
        if ! vm-podshift-systemctl "${vm}" start "${base}-volume.service"; then
            write-log "${run_dir}" postinstall-examples "start ${base}-volume.service failed"
            echo "Could not start ${base}-volume.service"
            return 1
        fi
        name="$(sed -n 's/^VolumeName=//p' "${file}" | tail -n 1)"
        fill+=("${name:-systemd-${base}}")
    done
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}" .container)"
        if ! vm-podshift-systemctl "${vm}" start "${base}.service"; then
            write-log "${run_dir}" postinstall-examples "start ${base}.service failed"
            echo "Could not start ${base}.service"
            return 1
        fi
    done
    for name in "${fill[@]}"; do
        if ! vm-podshift-run "${vm}" podman run --rm --quiet -v "${name}:/data" docker.io/library/alpine:latest \
            cp /etc/alpine-release /data/example.txt >/dev/null; then
            write-log "${run_dir}" postinstall-examples "writing a file into ${name} failed"
            echo "Could not write a file into the volume ${name}"
            return 1
        fi
    done
    write-log "${run_dir}" postinstall-examples "example volumes in place, ${count} files or volumes added or replaced"
    echo "NOTE: example volumes in place"
    return 0
}
