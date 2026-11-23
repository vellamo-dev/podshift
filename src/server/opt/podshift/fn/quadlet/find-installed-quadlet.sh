#!/usr/bin/env bash
# @file: find-installed-quadlet.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Prints each installed file with the given name, at the top of the quadlets directory or in an app folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the full path of every file named like the given quadlet in the quadlets directory, one app folder deep.
# @details:
#   A single file is installed at the top of the quadlets directory, a bundle in the folder
#   <quadlets>/<application>. Two files with the same name make the same systemd unit, so any match
#   means the name is taken. Nothing is changed or logged.
# @arg: $1 - quadlet file name, for example web.container.
# @arg: $2 - directory where Podman installs quadlets.
# @stdout: the full path of each match, one per line, sorted. Nothing if there is none.
# @exitcode: 0 if at least one file matches, 1 otherwise.
find-installed-quadlet() {
    local name quadlets_dir found
    name="${1-}"
    quadlets_dir="${2-}"
    quadlets_dir="${quadlets_dir%/}"
    [[ -n "${name}" && "${name}" != */* && -n "${quadlets_dir}" && -d "${quadlets_dir}" ]] || return 1
    found="$(find "${quadlets_dir}" -mindepth 1 -maxdepth 2 -type f -name "${name}" | LC_ALL=C sort)"
    [[ -n "${found}" ]] || return 1
    printf '%s\n' "${found}"
    return 0
}
