#!/usr/bin/env bash
# @file: find-duplicate-units.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Finds installed unit files that have the same file name as a unit file of an item about to be installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_CD080F20CCED:-}" ]]; then
    DIR_CD080F20CCED="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_CD080F20CCED
fi

# @description: Prints each file elsewhere in the quadlets directory that has the name of one of the item's unit files.
# @details:
#   Two unit files with the same name make the same systemd unit, so the last one installed wins.
#   The unit files of the item are the files with a Quadlet extension (.artifact, .build,
#   .container, .image, .kube, .network, .pod, .volume). The item lives in one place: the quadlets
#   directory itself for a single file, or the folder <quadlets>/<application> for a bundle (the
#   application name comes from get-app-name). Every file with the same name found in another place
#   of the quadlets directory (the top level or one application folder deep) is a duplicate. A file
#   in the item's own place is not: that is the item being replaced. Nothing is changed or logged.
# @arg: $1 - staged quadlet file or bundle folder, named by its original name.
# @arg: $2 - directory where Podman installs quadlets.
# @stdout: the full path of each duplicate, one per line. Nothing if there is none.
# @exitcode: 0 always.
find-duplicate-units() {
    local item quadlets_dir own_dir file name existing extension is_unit installed
    item="${1-}"
    quadlets_dir="${2-}"
    quadlets_dir="${quadlets_dir%/}"
    [[ -n "${item}" && -n "${quadlets_dir}" && -d "${quadlets_dir}" ]] || return 0

    if [[ -d "${item}" ]]; then
        # shellcheck source=./get-app-name.sh
        declare -F get-app-name >/dev/null || source "${DIR_CD080F20CCED}/get-app-name.sh"
        own_dir="${quadlets_dir}/$(get-app-name "${item}")"
    else
        own_dir="${quadlets_dir}"
    fi
    # No mapfile: the unit tests may run with the old bash of macOS.
    installed="$(find "${quadlets_dir}" -mindepth 1 -maxdepth 2 -type f | LC_ALL=C sort)"

    while IFS= read -r file; do
        name="$(basename "${file}")"
        is_unit=0
        for extension in artifact build container image kube network pod volume; do
            [[ "${name}" == *".${extension}" ]] && is_unit=1
        done
        (( is_unit == 1 )) || continue
        while IFS= read -r existing; do
            [[ -n "${existing}" ]] || continue
            [[ "$(basename "${existing}")" == "${name}" ]] || continue
            [[ "$(dirname "${existing}")" == "${own_dir}" ]] && continue
            printf '%s\n' "${existing}"
        done <<< "${installed}"
    done < <(if [[ -d "${item}" ]]; then find "${item}" -type f | LC_ALL=C sort; else printf '%s\n' "${item}"; fi)
    return 0
}
