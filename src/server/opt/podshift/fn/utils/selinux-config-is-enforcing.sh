#!/usr/bin/env bash
# @file: selinux-config-is-enforcing.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Returns 0 when a SELinux config file has SELINUX=enforcing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1AB77C5E625A:-}" ]]; then
    DIR_1AB77C5E625A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1AB77C5E625A
fi

# @description: Returns 0 when a SELinux config file has SELINUX=enforcing.
# @arg: $1 - path to the config file.
# @exitcode: 0 if the file sets SELINUX=enforcing, 1 otherwise.
selinux-config-is-enforcing() {
    local config line
    config="${1}"
    [[ -f "${config}" ]] || return 1
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ "${line}" == SELINUXTYPE=* ]]; then
            continue
        fi
        if [[ "${line}" == SELINUX=* ]]; then
            [[ "${line}" == "SELINUX=enforcing" ]]
            return
        fi
    done < "${config}"
    return 1
}
