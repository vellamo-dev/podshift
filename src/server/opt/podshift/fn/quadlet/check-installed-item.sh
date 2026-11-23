#!/usr/bin/env bash
# @file: check-installed-item.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Tells if a dropped quadlet file or bundle is new, already installed unchanged, or clashes with an installed one.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A5E17AC337FD:-}" ]]; then
    DIR_A5E17AC337FD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A5E17AC337FD
fi

# @description: Compares a dropped item with the installed quadlets: new, unchanged, or refused with a reason.
# @details:
#   An installed item is never replaced. A single file is unchanged when the same name is
#   installed at the top of the quadlets directory with the same content after filling
#   (is-same-installed-file); a different content there, or the same name in an app folder, is
#   refused. A bundle is unchanged when the app folder holds exactly the same file names, each with
#   the same content; any other installed app folder of that name is refused, and so is a bundle
#   file whose name is installed anywhere else. The TSV_ values must already be loaded.
# @arg: $1 - dropped quadlet file, or folder with the files of a bundle.
# @arg: $2 - directory where Podman installs quadlets.
# @arg: $3 - application name, for a bundle folder only.
# @stdout: the reason when the item is refused, one line.
# @exitcode: 0 if nothing of it is installed, 1 if refused, 2 if the same item is already installed (unchanged).
check-installed-item() {
    local item quadlets_dir app name file found app_dir new_names old_names
    item="${1-}"
    quadlets_dir="${2-}"
    app="${3-}"
    quadlets_dir="${quadlets_dir%/}"

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_A5E17AC337FD}/get-original-name.sh"
    # shellcheck source=./find-installed-quadlet.sh
    declare -F find-installed-quadlet >/dev/null || source "${DIR_A5E17AC337FD}/find-installed-quadlet.sh"
    # shellcheck source=./is-same-installed-file.sh
    declare -F is-same-installed-file >/dev/null || source "${DIR_A5E17AC337FD}/is-same-installed-file.sh"

    if [[ -f "${item}" ]]; then
        name="$(get-original-name "${item}")"
        found="$(find-installed-quadlet "${name}" "${quadlets_dir}")" || return 0
        if [[ "${found}" == "${quadlets_dir}/${name}" ]]; then
            is-same-installed-file "${item}" "${found}" && return 2
            echo "${name} is already installed, remove it first"
            return 1
        fi
        found="${found%%$'\n'*}"
        echo "${name} is already installed in app $(basename "$(dirname "${found}")"), remove it first"
        return 1
    fi

    [[ -d "${item}" && -n "${app}" ]] || return 1
    app_dir="${quadlets_dir}/${app}"
    if [[ -d "${app_dir}" ]]; then
        new_names="$(find "${item}" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | LC_ALL=C sort)"
        old_names="$(find "${app_dir}" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | LC_ALL=C sort)"
        if [[ "${new_names}" == "${old_names}" ]]; then
            while IFS= read -r name; do
                [[ -n "${name}" ]] || continue
                if ! is-same-installed-file "${item}/${name}" "${app_dir}/${name}"; then
                    echo "app ${app} is already installed, remove it first"
                    return 1
                fi
            done <<< "${new_names}"
            return 2
        fi
        echo "app ${app} is already installed, remove it first"
        return 1
    fi

    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        name="$(basename "${file}")"
        if found="$(find-installed-quadlet "${name}" "${quadlets_dir}")"; then
            found="${found%%$'\n'*}"
            echo "${name} is already installed (${found#"${quadlets_dir}/"}), remove it first"
            return 1
        fi
    done < <(find "${item}" -mindepth 1 -maxdepth 1 -type f | LC_ALL=C sort)
    return 0
}
