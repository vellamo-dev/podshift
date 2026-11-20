#!/usr/bin/env bash
# @file: selinux-write-config.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Sets SELINUX=enforcing in a SELinux config file and keeps the rest of the file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_BBB5B1C921AE:-}" ]]; then
    DIR_BBB5B1C921AE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_BBB5B1C921AE
fi

# @description: Sets SELINUX=enforcing in a SELinux config file and keeps the rest of the file.
# @arg: $1 - path to the config file.
# @stderr: errors when the file is missing or cannot be written.
# @exitcode: 0 on success, 1 on failure.
selinux-write-config() {
    local config tmp line found
    config="${1}"
    tmp="${config}.podshift-tmp.$$"
    found=0
    if [[ ! -f "${config}" ]]; then
        echo "The file ${config} was not found." >&2
        return 1
    fi
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" == SELINUXTYPE=* ]]; then
            printf '%s\n' "${line}"
        elif [[ "${line}" == SELINUX=* ]]; then
            printf 'SELINUX=enforcing\n'
            found=1
        else
            printf '%s\n' "${line}"
        fi
    done < "${config}" > "${tmp}" || {
        rm -f "${tmp}"
        echo "Failed to update ${config}." >&2
        return 1
    }
    if [[ "${found}" -eq 0 ]]; then
        printf 'SELINUX=enforcing\n' >> "${tmp}"
    fi
    if ! cat "${tmp}" > "${config}"; then
        rm -f "${tmp}"
        echo "Failed to update ${config}." >&2
        return 1
    fi
    rm -f "${tmp}"
    return 0
}
