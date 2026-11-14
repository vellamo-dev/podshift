#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/images-list
# @dest-dir: /opt/podshift/cockpit/api/modules/images-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Images list module: lists the podshift user's Podman images as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1D7066C59B4E:-}" ]]; then
    DIR_1D7066C59B4E="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1D7066C59B4E
fi

# shellcheck source=../../fn/resources/cockpit-images-items.sh
declare -F cockpit-images-items >/dev/null || source "${DIR_1D7066C59B4E}/../../fn/resources/cockpit-images-items.sh"
# shellcheck source=../../fn/resources/cockpit-images-quadlet-ref.sh
declare -F cockpit-images-quadlet-ref >/dev/null || source "${DIR_1D7066C59B4E}/../../fn/resources/cockpit-images-quadlet-ref.sh"

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-images-list-podman() {
    podman "$@"
}

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments after --user.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code, or 1 when systemctl is missing.
cockpit-images-list-systemctl() {
    systemctl --user "$@"
}

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-images-list-quadlet-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_1D7066C59B4E}/../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    if [[ -n "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        printf '%s\n' "${PODSHIFT_PODMAN_QUADLETS_DIR}"
    fi
    return 0
}

# @description: Shortens a path under HOME to ~/... for display.
# @arg: $1 - path.
# @stdout: the display path.
# @exitcode: 0 always.
cockpit-images-list-display-path() {
    local path
    path="${1-}"
    if [[ -n "${HOME:-}" && "${path}" == "${HOME}/"* ]]; then
        path="~/${path#"${HOME}/"}"
    fi
    printf '%s\n' "${path}"
}

# @description: Prints the application name for a file in a bundle folder of the installed-quadlet directory.
# @arg: $1 - file path.
# @arg: $2 - the installed-quadlet directory.
# @stdout: the application name, or nothing when the file is not in a bundle folder.
# @exitcode: 0 always.
cockpit-images-list-app() {
    local file dir parent
    file="${1-}"
    dir="${2-}"
    dir="${dir%/}"
    [[ -n "${file}" && -n "${dir}" && "${file}" == "${dir}/"*/* ]] || return 0
    parent="${file%/*}"
    [[ "${parent%/*}" == "${dir}" ]] || return 0
    # shellcheck source=../../../../fn/quadlet/get-app-name.sh
    declare -F get-app-name >/dev/null || source "${DIR_1D7066C59B4E}/../../../../fn/quadlet/get-app-name.sh"
    get-app-name "${parent##*/}"
    return 0
}

# @description: Prints the ActiveState and the source file of one systemd user unit.
# @details:
#   The file is SourcePath (the Quadlet file for a generated unit), else FragmentPath. Values that
#   cannot be read are left empty.
# @arg: $1 - unit name.
# @stdout: one line, <state><TAB><file>.
# @exitcode: 0 always.
cockpit-images-list-unit-info() {
    local out line state source fragment
    out="$(cockpit-images-list-systemctl show -p ActiveState -p SourcePath -p FragmentPath -- "${1-}" 2>/dev/null)" || out=""
    state=""
    source=""
    fragment=""
    while IFS= read -r line; do
        case "${line}" in
            ActiveState=*) state="${line#ActiveState=}" ;;
            SourcePath=*) source="${line#SourcePath=}" ;;
            FragmentPath=*) fragment="${line#FragmentPath=}" ;;
        esac
    done <<< "${out}"
    printf '%s\t%s\n' "${state}" "${source:-${fragment}}"
    return 0
}

# @description: Prints podman image inspect JSON for every image of the current (podshift) user.
# @details:
#   IDs come from podman image ls --format json. With no images the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-images-list-inspect() {
    local raw
    local -a ids
    raw="$(cockpit-images-list-podman image ls --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    cockpit-images-list-podman image inspect -- "${ids[@]}" 2>/dev/null
}

# @description: Prints podman ps -a JSON for every container of the current (podshift) user.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-images-list-containers() {
    local raw
    raw="$(cockpit-images-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    printf '%s\n' "${raw}"
}

# @description: Prints the source map for images pulled by Quadlet .image files.
# @details:
#   Every *.image file in the installed-quadlet directory, or one bundle folder below it, gives
#   {source:quadlet, unit:<base>-image.service, unit_state, file, app} under the reference from
#   cockpit-images-quadlet-ref. app is set only for files in a bundle folder. When two files pull
#   the same reference, the first one in sorted path order wins.
# @stdout: one JSON object mapping an image reference to its source entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-images-list-sources() {
    local sources dir file base ref unit info state app text
    sources='{}'
    dir="$(cockpit-images-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            base="${file##*/}"
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            ref="$(cockpit-images-quadlet-ref "${text}")" || continue
            unit="${base%.image}-image.service"
            info="$(cockpit-images-list-unit-info "${unit}")"
            state="${info%%$'\t'*}"
            app="$(cockpit-images-list-app "${file}" "${dir}")"
            sources="$(jq -c -n --argjson s "${sources}" --arg ref "${ref}" --arg unit "${unit}" \
                --arg state "${state}" --arg file "$(cockpit-images-list-display-path "${file}")" --arg app "${app}" \
                'if $s[$ref] then $s else $s + {($ref): ({source: "quadlet", unit: $unit, unit_state: $state, file: $file}
                    + (if $app == "" then {} else {app: $app} end))} end')" || return 1
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.image' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    printf '%s\n' "${sources}"
}

# @description: Prints the state, file and app of every systemd unit named by a container label.
# @details:
#   The units are the PODMAN_SYSTEMD_UNIT labels of the containers. The file is shown as ~/...,
#   and app is set when the file is in a bundle folder of the installed-quadlet directory.
# @arg: $1 - JSON array from podman ps -a --format json.
# @stdout: one JSON object mapping a unit name to {unit_state, file, app}.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-images-list-units() {
    local ctrs units dir unit info state file app
    ctrs="${1-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    units='{}'
    dir="$(cockpit-images-list-quadlet-dir)"
    while IFS= read -r unit; do
        [[ -n "${unit}" ]] || continue
        info="$(cockpit-images-list-unit-info "${unit}")"
        state="${info%%$'\t'*}"
        file="${info#*$'\t'}"
        app="$(cockpit-images-list-app "${file}" "${dir}")"
        units="$(jq -c -n --argjson u "${units}" --arg unit "${unit}" --arg state "${state}" \
            --arg file "$(cockpit-images-list-display-path "${file}")" --arg app "${app}" \
            '$u + {($unit): ({unit_state: $state} + (if $file == "" then {} else {file: $file} end)
                + (if $app == "" then {} else {app: $app} end))}')" || return 1
    done < <(printf '%s' "${ctrs}" | jq -r '[.[]? | (.Labels // {}) | objects | .PODMAN_SYSTEMD_UNIT // empty] | unique | .[]' 2>/dev/null)
    printf '%s\n' "${units}"
}

# @description: Lists the podshift user's Podman images as resource cards.
# @details:
#   Reads podman image ls, podman image inspect and podman ps -a, then finds which images come
#   from a Quadlet .image file and which are used by a container with a systemd unit. The items
#   are built by cockpit-images-items. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-images-list() {
    local images ctrs sources units
    images="$(cockpit-images-list-inspect)" || return 1
    [[ -n "${images}" ]] || images='[]'
    ctrs="$(cockpit-images-list-containers)" || return 1
    sources="$(cockpit-images-list-sources)" || return 1
    units="$(cockpit-images-list-units "${ctrs}")" || return 1
    cockpit-images-items "${images}" "${ctrs}" "${sources}" "${units}"
}
