#!/usr/bin/env bash
# @file: selinux-set-enforcing.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Switches SELinux to enforcing and sets SELINUX=enforcing in the config file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4AB486171993:-}" ]]; then
    DIR_4AB486171993="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4AB486171993
fi

# @description: Runs setenforce 1, then sets SELINUX=enforcing in the config file.
# @arg: $1 - path to the SELinux config file.
# @stderr: errors from selinux-write-config when the config file cannot be updated.
# @exitcode: 0 on success, 1 if setenforce failed (config unchanged), 2 if no config file was given (nothing changed) or it could not be updated.
selinux-set-enforcing() {
    local config
    config="${1:-}"
    [[ -n "${config}" ]] || return 2
    if ! setenforce 1; then
        return 1
    fi
    # shellcheck source=selinux-write-config.sh
    declare -F selinux-write-config >/dev/null || source "${DIR_4AB486171993}/selinux-write-config.sh"
    selinux-write-config "${config}" || return 2
    return 0
}
