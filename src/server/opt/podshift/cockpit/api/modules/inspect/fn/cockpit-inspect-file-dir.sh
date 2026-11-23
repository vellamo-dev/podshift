#!/usr/bin/env bash
# @file: cockpit-inspect-file-dir.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/inspect/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/inspect/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the folder for inspect files in the user's runtime directory, creating it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the folder for inspect files in the user's runtime directory, creating it.
# @details:
#   The folder is $XDG_RUNTIME_DIR/podshift, or /run/user/<uid>/podshift when XDG_RUNTIME_DIR is
#   not set. It is created with mode 0700 and must be a real folder owned by this user.
# @stdout: the folder path.
# @exitcode: 0 when the folder is usable, 1 otherwise.
cockpit-inspect-file-dir() {
    local base dir
    base="${XDG_RUNTIME_DIR:-/run/user/${EUID}}"
    [[ "${base}" == /* && -d "${base}" ]] || return 1
    dir="${base}/podshift"
    if [[ ! -e "${dir}" ]]; then
        mkdir -m 0700 -- "${dir}" 2>/dev/null || return 1
    fi
    [[ -d "${dir}" && ! -L "${dir}" && -O "${dir}" ]] || return 1
    printf '%s\n' "${dir}"
}
