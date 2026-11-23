#!/usr/bin/env bash
# @file: check-quadlet-install.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Checks that a new quadlet file can be installed: its Podman names are free and its references are there.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3328FC0253FD:-}" ]]; then
    DIR_3328FC0253FD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3328FC0253FD
fi

# @description: Runs check-quadlet-names-free, then check-quadlet-deps, and prints the first reason.
# @arg: $1 - dropped quadlet file.
# @arg: $2 - directory where Podman installs quadlets.
# @arg: $3 - quadlet source directory.
# @arg: $4 - folder with the other files of the same bundle, or empty for a single file.
# @stdout: the reason when the file cannot be installed, one line.
# @exitcode: 0 if it can be installed, 1 otherwise.
check-quadlet-install() {
    local file quadlets_dir source_dir own_dir
    file="${1-}"
    quadlets_dir="${2-}"
    source_dir="${3-}"
    own_dir="${4-}"

    # shellcheck source=./check-quadlet-names-free.sh
    declare -F check-quadlet-names-free >/dev/null || source "${DIR_3328FC0253FD}/check-quadlet-names-free.sh"
    check-quadlet-names-free "${file}" "${quadlets_dir}" "${own_dir}" || return 1
    # shellcheck source=./check-quadlet-deps.sh
    declare -F check-quadlet-deps >/dev/null || source "${DIR_3328FC0253FD}/check-quadlet-deps.sh"
    check-quadlet-deps "${file}" "${quadlets_dir}" "${source_dir}" "${own_dir}" || return 1
    return 0
}
