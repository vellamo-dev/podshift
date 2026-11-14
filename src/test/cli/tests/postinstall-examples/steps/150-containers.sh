#!/usr/bin/env bash
# @file: 150-containers.sh
# @source-dir: src/test/cli/tests/postinstall-examples/steps
# @group: test
# @category: step
# @description: Example containers added.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Adds one example container of each source and state: Quadlet, user service and unmanaged.
# @details:
#   Installs the .container files into PODSHIFT_PODMAN_QUADLETS_DIR and the .service files into
#   ~/.config/systemd/user of the podshift user, runs daemon-reload, starts the Quadlet container
#   units (<base>.service), enables and starts the services (each runs its container once), then
#   runs each container in unmanaged.list with podman run --replace on alpine, labeled
#   podshift.example=1. A running or paused line runs sleep infinity detached, a paused line is then
#   paused, and an exited line runs echo and stops. Runs last, after the secrets step, so the
#   example containers that use secrets (example-secret-quadlet and example-secret-stopped) find
#   them. Existing files and containers are replaced, so it can run again.
# @arg: $1 - the run folder.
# @stdout: NOTE with what was added, or the problem.
# @exitcode: 0 if all were added, 1 on an error, 3 if the VM is not running.
containers() {
    local run_dir vm dir file base name state opts line count image err rc
    run_dir="${1}"
    vm="${TST_RPM_INSTALLER_VM}"
    dir="${TST_EXAMPLES_DIR}/containers"
    image="docker.io/library/alpine:latest"
    if ! vm-running "${vm}"; then
        echo "The VM ${vm} is not running"
        echo "Fix: ./test bundle-build-install-validate"
        return 3
    fi
    count=0
    for file in "${dir}"/example-*.container; do
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
    for file in "${dir}"/example-*.container; do
        [[ -f "${file}" ]] || continue
        base="$(basename "${file}" .container)"
        if ! vm-podshift-systemctl "${vm}" start "${base}.service"; then
            write-log "${run_dir}" postinstall-examples "start ${base}.service failed"
            echo "Could not start ${base}.service"
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
        state="${opts%% *}"
        opts="${opts#"${state}"}"
        case "${state}" in
            running|paused)
                # Not vm-podshift-run: conmon stays in the cgroup of the transient unit and ignores SIGTERM,
                # so the unit would time out on stop and kill it. KillMode=process leaves conmon running, and
                # without --pipe conmon does not keep the SSH pipe open.
                # shellcheck disable=SC2086
                err="$(vm-run "${vm}" systemd-run --machine=podshift@.host --user --quiet --wait --collect \
                    -p KillMode=process -- podman run --replace --detach --name "${name}" --label podshift.example=1 \
                    ${opts} "${image}" sleep infinity 2>&1 >/dev/null)"
                rc=$?
                if [[ "${rc}" -ne 0 ]]; then
                    write-log "${run_dir}" postinstall-examples "podman run ${name} failed (exit ${rc}): ${err}"
                    echo "Could not run the container ${name} (exit ${rc}): ${err}"
                    return 1
                fi
                ;;
            exited)
                # shellcheck disable=SC2086
                if ! err="$(vm-podshift-run "${vm}" podman run --replace --name "${name}" --label podshift.example=1 \
                    ${opts} "${image}" echo PodShift example 2>&1 >/dev/null)"; then
                    write-log "${run_dir}" postinstall-examples "podman run ${name} failed: ${err}"
                    echo "Could not run the container ${name}: ${err}"
                    return 1
                fi
                ;;
            *)
                echo "Unknown state ${state} for ${name} in unmanaged.list"
                return 1
                ;;
        esac
        if [[ "${state}" == "paused" ]] && ! vm-podshift-run "${vm}" podman pause "${name}" >/dev/null; then
            write-log "${run_dir}" postinstall-examples "podman pause ${name} failed"
            echo "Could not pause the container ${name}"
            return 1
        fi
        count=$((count + 1))
    done <<< "$(example-network-lines "${dir}/unmanaged.list")"
    write-log "${run_dir}" postinstall-examples "example containers in place, ${count} files or containers added or replaced"
    echo "NOTE: example containers in place"
    return 0
}
