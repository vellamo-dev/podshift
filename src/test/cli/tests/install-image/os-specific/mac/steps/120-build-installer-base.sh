#!/usr/bin/env bash
# @file: 120-build-installer-base.sh
# @source-dir: src/test/cli/tests/install-image/os-specific/mac/steps
# @group: test
# @category: step
# @description: Build RPM installer VM base.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Builds the stopped Lima base VM that the RPM installer VM is cloned from, or reuses it if it is new enough.
# @details:
#   The base VM is TST_RPM_INSTALLER_BASE, and install-vm-start clones from it. It is rebuilt when
#   reuse is off, it is missing or running, the Lima config TST_LIMA_CONFIG is newer, or it is
#   older than TST_RPM_INSTALLER_MAX_AGE_HOURS. Its age is the time its lima.yaml was written,
#   which Lima changes only when the VM is created. A build runs limactl start with the config and
#   the test VM SSH key for root, empties /etc/machine-id so every clone makes its own, and stops
#   it. Lima gives the base its own MAC address, so it never clashes with the test VM. The limactl
#   output is saved to lima-base-start.log in the run folder.
# @arg: $1 - the run folder.
# @stdout: NOTE with what happened and why, and the end of the limactl output on failure.
# @exitcode: 0 if the base is ready, 1 otherwise.
build-installer-base() {
    local run_dir base file key mem log dir age shown reason
    run_dir="${1}"
    base="${TST_RPM_INSTALLER_BASE}"
    file="${TST_LIMA_CONFIG}"
    key="${HOME}/.ssh/podshift-test-vm.pub"
    log="${run_dir}/lima-base-start.log"
    age=""
    dir=""
    if vm-exists "${base}"; then
        dir="$(vm list --format '{{.Dir}}' "${base}" 2>/dev/null)"
        age="$(file-age "${dir}/lima.yaml")"
    fi
    shown=""
    [[ -z "${age}" ]] || shown="$(format-age "${age}")"
    reason=""
    [[ "${TST_RPM_INSTALLER_REUSE}" == "true" ]] || reason="reuse off"
    [[ -n "${reason}" || -n "${age}" ]] || reason="no base"
    [[ -n "${reason}" ]] || ! vm-running "${base}" || reason="base was running"
    [[ -n "${reason}" || ! "${file}" -nt "${dir}/lima.yaml" ]] || reason="new Lima config"
    [[ -n "${reason}" || "${age}" -lt $(( TST_RPM_INSTALLER_MAX_AGE_HOURS * 3600 )) ]] \
        || reason="${shown} old, max ${TST_RPM_INSTALLER_MAX_AGE_HOURS}h"
    if [[ -z "${reason}" ]]; then
        write-log "${run_dir}" install-image "Base ${base}: reused, ${shown} old, max ${TST_RPM_INSTALLER_MAX_AGE_HOURS}h"
        echo "NOTE: reused, ${shown} old"
        return 0
    fi
    case "${TST_RPM_INSTALLER_MEMORY}" in
        *G) mem="${TST_RPM_INSTALLER_MEMORY%G}" ;;
        *)  echo "TST_RPM_INSTALLER_MEMORY must end in G, for example 8G, not ${TST_RPM_INSTALLER_MEMORY}"; return 1 ;;
    esac
    if [[ ! -f "${file}" ]]; then
        write-log "${run_dir}" install-image "Lima config ${file}: missing"
        echo "The Lima config ${file} does not exist"
        return 1
    fi
    if [[ ! -f "${key}" ]]; then
        write-log "${run_dir}" install-image "SSH key ${key}: missing"
        echo "The test VM SSH key ${key} is missing"
        return 1
    fi
    if vm-exists "${base}"; then
        vm delete -f "${base}" >/dev/null 2>&1 || { echo "The old base VM ${base} could not be removed"; return 1; }
    fi
    if ! vm start --tty=false --timeout "${TST_LIMA_START_TIMEOUT}" --name "${base}" \
        --cpus "${TST_RPM_INSTALLER_CPUS}" --memory "${mem}" \
        --param "SshPubKey=$(cat "${key}")" \
        "${file}" >"${log}" 2>&1; then
        write-log "${run_dir}" install-image "Base ${base}: limactl start failed (${reason}), see ${log}"
        tail -n 20 "${log}"
        echo "The base VM ${base} could not be built, see ${log}"
        return 1
    fi
    # Lima's own SSH works here, since the base never gets PodShift and keeps SSH on port 22.
    if ! vm shell --tty=false "${base}" sudo truncate -s 0 /etc/machine-id >>"${log}" 2>&1; then
        write-log "${run_dir}" install-image "Base ${base}: machine-id could not be emptied, see ${log}"
        echo "The machine-id of the base VM ${base} could not be emptied, see ${log}"
        return 1
    fi
    if ! vm stop "${base}" >>"${log}" 2>&1; then
        write-log "${run_dir}" install-image "Base ${base}: could not be stopped, see ${log}"
        echo "The base VM ${base} could not be stopped, see ${log}"
        return 1
    fi
    write-log "${run_dir}" install-image "Base ${base}: built, ${reason}, from ${file}"
    echo "NOTE: built, ${reason}"
}
