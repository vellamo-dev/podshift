#!/usr/bin/env bash
# @file: vm-podshift-run.sh
# @source-dir: src/test/cli/shared/fn/vm
# @group: test
# @category: helper
# @description: Runs a command as the podshift user, in its systemd user session, inside a VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs a command in the podshift user session of a VM, the same way the Cockpit API does.
# @details:
#   Uses systemd-run --machine=podshift@.host --user --wait --pipe, so podman and other
#   commands see that user's storage and runtime folder. The arguments are split again inside the
#   VM (see vm-run), so pass simple words.
# @arg: $1 - the VM name.
# @arg: $2... - the command and its arguments.
# @stdout: the command output.
# @exitcode: the command's exit code, or 255 if SSH could not connect.
vm-podshift-run() {
    local name
    name="${1}"
    shift
    vm-run "${name}" systemd-run --machine=podshift@.host --user --quiet --wait --pipe --collect -- "$@"
}

# @description: Runs systemctl --user for the podshift user in a VM.
# @arg: $1 - the VM name.
# @arg: $2... - systemctl arguments after --user.
# @stdout: the systemctl output.
# @exitcode: the systemctl exit code, or 255 if SSH could not connect.
vm-podshift-systemctl() {
    local name
    name="${1}"
    shift
    vm-run "${name}" systemctl --machine=podshift@.host --user "$@"
}

# @description: Copies a host file into a folder of the podshift user in a VM, owned by podshift.
# @details:
#   The file is copied to TST_EXAMPLES_VM_TMP first, then put in place with install, which
#   creates the folder when needed and replaces an existing file. Running it again gives the same
#   result.
# @arg: $1 - the VM name.
# @arg: $2 - the host file.
# @arg: $3 - the folder in the VM, under /home/podshift.
# @stdout: the problem if any.
# @exitcode: 0 if the file is in place, 1 otherwise.
vm-podshift-install-file() {
    local name file dir base
    name="${1}"
    file="${2}"
    dir="${3}"
    base="$(basename -- "${file}")"
    if [[ "${dir}" != /home/podshift/* ]]; then
        echo "Refusing to install ${base} outside /home/podshift: ${dir}"
        return 1
    fi
    vm-run "${name}" mkdir -p "${TST_EXAMPLES_VM_TMP}" || { echo "Could not create ${TST_EXAMPLES_VM_TMP} in ${name}"; return 1; }
    vm-copy "${name}" "${file}" "${TST_EXAMPLES_VM_TMP}" || { echo "Could not copy ${base} to ${name}"; return 1; }
    vm-run "${name}" runuser -u podshift -- mkdir -p "${dir}" || { echo "Could not create ${dir} in ${name}"; return 1; }
    vm-run "${name}" install -o podshift -g podshift -m 0644 "${TST_EXAMPLES_VM_TMP}/${base}" "${dir}/${base}" \
        || { echo "Could not install ${base} into ${dir}"; return 1; }
    vm-run "${name}" rm -f "${TST_EXAMPLES_VM_TMP}/${base}" || true
    return 0
}
