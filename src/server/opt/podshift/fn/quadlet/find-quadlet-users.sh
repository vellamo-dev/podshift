#!/usr/bin/env bash
# @file: find-quadlet-users.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Prints each installed quadlet file that refers to one of the given quadlet file names.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5C20882F6BA5:-}" ]]; then
    DIR_5C20882F6BA5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5C20882F6BA5
fi

# @description: Prints the installed files, outside the part being removed, whose references (list-quadlet-deps) name one of the files.
# @details:
#   Reads every file at the top of the quadlets directory and one app folder deep. The part being
#   removed (one file, or one app folder) is skipped, so files of one app may refer to each other.
#   A plain:<name> reference counts like the file name, so Network=web is a user of web.network.
#   Nothing is changed or logged.
# @arg: $1 - directory where Podman installs quadlets.
# @arg: $2 - the installed file or app folder being removed, skipped.
# @arg: $@ - from $3 on, the quadlet file names being removed, for example web.network.
# @stdout: the path of each user, relative to the quadlets directory, one per line, sorted.
# @exitcode: 0 if at least one user was found, 1 otherwise.
find-quadlet-users() {
    local quadlets_dir skip file ref found
    local -a names
    quadlets_dir="${1-}"
    skip="${2-}"
    names=("${@:3}")
    quadlets_dir="${quadlets_dir%/}"
    skip="${skip%/}"
    [[ -n "${quadlets_dir}" && -d "${quadlets_dir}" && ${#names[@]} -gt 0 ]] || return 1

    # shellcheck source=./list-quadlet-deps.sh
    declare -F list-quadlet-deps >/dev/null || source "${DIR_5C20882F6BA5}/list-quadlet-deps.sh"
    found=""
    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        [[ "${file}" == "${skip}" || "${file}" == "${skip}/"* ]] && continue
        while IFS= read -r ref; do
            ref="${ref#plain:}"
            if [[ " ${names[*]} " == *" ${ref} "* ]]; then
                found+="${file#"${quadlets_dir}/"}"$'\n'
                break
            fi
        done < <(list-quadlet-deps "${file}")
    done < <(find "${quadlets_dir}" -mindepth 1 -maxdepth 2 -type f | LC_ALL=C sort)
    [[ -n "${found}" ]] || return 1
    printf '%s' "${found}"
    return 0
}
