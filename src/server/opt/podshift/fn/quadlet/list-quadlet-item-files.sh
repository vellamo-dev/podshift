#!/usr/bin/env bash
# @file: list-quadlet-item-files.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Lists the files of one installed Quadlet file name or app name.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_BABB4B85126B:-}" ]]; then
    DIR_BABB4B85126B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_BABB4B85126B
fi

# @description: Prints the path of each file of one installed Quadlet file (web.container) or app (shop).
# @details:
#   A name with a Quadlet extension whose stem is a valid app name is a single file at the top of
#   the quadlets directory. Any other valid app name (is-valid-app-name) is an app folder there,
#   and its files are listed sorted. A name never holds a slash. quadlet-remove and remove-item
#   both use it, so they agree on what a name means.
# @arg: $1 - directory where Podman installs quadlets.
# @arg: $2 - quadlet file name or app name.
# @stdout: the path of each file, one per line.
# @exitcode: 0 when it is installed, 1 when the file is not installed, 2 when the app is not installed, 3 when the name is not valid.
list-quadlet-item-files() {
    local quadlets_dir name path
    quadlets_dir="${1-}"
    name="${2-}"
    quadlets_dir="${quadlets_dir%/}"
    # shellcheck source=./is-valid-app-name.sh
    declare -F is-valid-app-name >/dev/null || source "${DIR_BABB4B85126B}/is-valid-app-name.sh"
    # shellcheck source=./get-quadlet-unit-name.sh
    declare -F get-quadlet-unit-name >/dev/null || source "${DIR_BABB4B85126B}/get-quadlet-unit-name.sh"
    [[ -n "${quadlets_dir}" && -n "${name}" && "${name}" != */* ]] || return 3
    path="${quadlets_dir}/${name}"
    if get-quadlet-unit-name "${name}" >/dev/null && is-valid-app-name "${name%.*}"; then
        [[ -f "${path}" ]] || return 1
        printf '%s\n' "${path}"
        return 0
    fi
    is-valid-app-name "${name}" || return 3
    [[ -d "${path}" ]] || return 2
    find "${path}" -mindepth 1 -maxdepth 1 -type f | LC_ALL=C sort
    return 0
}
