#!/usr/bin/env bash
# @file: 510-verify-ui-file-list.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files/steps
# @group: test
# @category: step
# @description: Verify the UI file list.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the relative file list in the installed UI matches the local dist.
# @arg: $1 - the run folder.
# @stdout: NOTE with the file count or skipped, DETAIL for missing or extra files, or the problem.
# @exitcode: 0 if the lists match or skipped, 2 if they differ, 1 if a list could not be made.
verify-ui-file-list() {
    local run_dir dest host_tmp host_file vm_file count missing extra
    run_dir="${1}"
    dest=/usr/share/cockpit/podshift
    host_tmp="artifacts/work/postinstall-ui-sync-files"
    if [[ -z "${TST_DEV_SHARE}" || ! -d "${TST_DEV_SHARE}" ]]; then
        echo "NOTE: skipped"
        return 0
    fi
    if vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q "${dest}" \
        || vm-run "${TST_RPM_INSTALLER_VM}" mountpoint -q /usr/local/share/cockpit/podshift; then
        echo "NOTE: skipped"
        return 0
    fi
    mkdir -p "${host_tmp}" || { echo "The folder ${host_tmp} could not be created"; return 1; }
    host_file="${host_tmp}/host-files.txt"
    vm_file="${host_tmp}/vm-files.txt"
    if ! (
        CDPATH='' cd -P -- "${TST_DEV_SHARE}" || exit 1
        find . -type f ! -name '.DS_Store' ! -name '._*'
    ) | sed 's|^\./||' | sort >"${host_file}"; then
        echo "The local UI dist file list could not be made"
        return 1
    fi
    if ! vm-run "${TST_RPM_INSTALLER_VM}" find "${dest}" -type f >"${vm_file}.raw"; then
        rm -f "${host_file}" "${vm_file}.raw"
        echo "The UI file list in the VM could not be read"
        return 1
    fi
    sed "s|^${dest}/||" "${vm_file}.raw" | sort >"${vm_file}"
    rm -f "${vm_file}.raw"
    if ! cmp -s "${host_file}" "${vm_file}"; then
        write-log "${run_dir}" postinstall-ui-sync-files "UI file list: does not match ${TST_DEV_SHARE}"
        echo "The UI file list in ${dest} does not match the local dist"
        missing="$(comm -23 "${host_file}" "${vm_file}")"
        extra="$(comm -13 "${host_file}" "${vm_file}")"
        [[ -z "${missing}" ]] || printf '%s\n' "${missing}" | sed 's/^/DETAIL: missing in VM: /'
        [[ -z "${extra}" ]] || printf '%s\n' "${extra}" | sed 's/^/DETAIL: extra in VM: /'
        rm -f "${host_file}" "${vm_file}"
        return 2
    fi
    count="$(grep -c . "${host_file}" || true)"
    write-log "${run_dir}" postinstall-ui-sync-files "UI file list: ${count} files match ${TST_DEV_SHARE}"
    rm -f "${host_file}" "${vm_file}"
    echo "NOTE: ${count} files"
}
