#!/usr/bin/env bash
# @file: cockpit-containers-list-app.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the application name for a file in a bundle folder of the installed-quadlet directory.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3A7FB64AA86E:-}" ]]; then
    DIR_3A7FB64AA86E="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3A7FB64AA86E
fi

# @description: Prints the application name for a file in a bundle folder of the installed-quadlet directory.
# @arg: $1 - file path.
# @arg: $2 - the installed-quadlet directory.
# @stdout: the application name, or nothing when the file is not in a bundle folder.
# @exitcode: 0 always.
cockpit-containers-list-app() {
    local file dir parent
    file="${1-}"
    dir="${2-}"
    dir="${dir%/}"
    [[ -n "${file}" && -n "${dir}" && "${file}" == "${dir}/"*/* ]] || return 0
    parent="${file%/*}"
    [[ "${parent%/*}" == "${dir}" ]] || return 0
    # shellcheck source=../../../../../fn/quadlet/get-app-name.sh
    declare -F get-app-name >/dev/null || source "${DIR_3A7FB64AA86E}/../../../../../fn/quadlet/get-app-name.sh"
    get-app-name "${parent##*/}"
    return 0
}
