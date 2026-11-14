#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Volumes list module: lists the podshift user's Podman volumes as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_BFE741360D80:-}" ]]; then
    DIR_BFE741360D80="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_BFE741360D80
fi

# shellcheck source=../../fn/resources/cockpit-volumes-items.sh
declare -F cockpit-volumes-items >/dev/null || source "${DIR_BFE741360D80}/../../fn/resources/cockpit-volumes-items.sh"
# shellcheck source=../../fn/resources/cockpit-volumes-quadlet-name.sh
declare -F cockpit-volumes-quadlet-name >/dev/null || source "${DIR_BFE741360D80}/../../fn/resources/cockpit-volumes-quadlet-name.sh"

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-volumes-list-podman() {
    podman "$@"
}

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments after --user.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code, or 1 when systemctl is missing.
cockpit-volumes-list-systemctl() {
    systemctl --user "$@"
}

# @description: Prints the disk usage of one folder in bytes, limited to 5 seconds.
# @details:
#   Runs du -sb (GNU coreutils). Files that the podshift user cannot read, such as files that a
#   container wrote with another subuid, are skipped by du, so the number can be too small. du then
#   exits non-zero, but its number is still printed. Nothing is printed on a timeout.
# @arg: $1 - folder path.
# @stdout: du output, <bytes><TAB><path>, or nothing.
# @exitcode: the du exit code; callers use the output, not the code.
cockpit-volumes-list-du() {
    if command -v timeout >/dev/null 2>&1; then
        timeout 5 du -sb -- "${1-}" 2>/dev/null
    else
        du -sb -- "${1-}" 2>/dev/null
    fi
}

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-volumes-list-quadlet-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_BFE741360D80}/../../../../fn/load-podshift-conf-main.sh"
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
cockpit-volumes-list-display-path() {
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
cockpit-volumes-list-app() {
    local file dir parent
    file="${1-}"
    dir="${2-}"
    dir="${dir%/}"
    [[ -n "${file}" && -n "${dir}" && "${file}" == "${dir}/"*/* ]] || return 0
    parent="${file%/*}"
    [[ "${parent%/*}" == "${dir}" ]] || return 0
    # shellcheck source=../../../../fn/quadlet/get-app-name.sh
    declare -F get-app-name >/dev/null || source "${DIR_BFE741360D80}/../../../../fn/quadlet/get-app-name.sh"
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
cockpit-volumes-list-unit-info() {
    local out line state source fragment
    out="$(cockpit-volumes-list-systemctl show -p ActiveState -p SourcePath -p FragmentPath -- "${1-}" 2>/dev/null)" || out=""
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

# @description: Prints podman volume inspect JSON for every volume of the current (podshift) user.
# @details:
#   Names come from podman volume ls --format json. With no volumes the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-volumes-list-inspect() {
    local raw
    local -a names
    raw="$(cockpit-volumes-list-podman volume ls --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t names < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Name // .name // empty)] | unique | .[]')
    if [[ "${#names[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    cockpit-volumes-list-podman volume inspect -- "${names[@]}" 2>/dev/null
}

# @description: Prints podman ps -a JSON for every container, each with the names of the volumes it mounts.
# @details:
#   podman ps lists only mount destinations, so the volume names come from podman container
#   inspect (.Mounts entries of type volume) and are added as VolumeNames.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman or jq fails.
cockpit-volumes-list-containers() {
    local raw mounts
    local -a ids
    raw="$(cockpit-volumes-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    mounts="$(cockpit-volumes-list-podman container inspect -- "${ids[@]}" 2>/dev/null)" || return 1
    [[ -n "${mounts}" ]] || mounts='[]'
    jq -n -c --argjson ps "${raw}" --argjson ins "${mounts}" '
        ([$ins[]? | {key: ((.Id // "") | tostring),
            value: [(.Mounts // [])[] | objects | select((.Type // "") == "volume") | .Name // empty]}]
            | from_entries) as $m
        | [$ps[] | . + {VolumeNames: ($m[(.Id // "") | tostring] // [])}]
    '
}

# @description: Prints the size in bytes of every volume mountpoint, from du.
# @details:
#   A volume whose size cannot be read, or whose du timed out, is left out of the map.
# @arg: $1 - JSON array from podman volume inspect.
# @stdout: one JSON object mapping a volume name to its size in bytes.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-volumes-list-sizes() {
    local vols sizes name path out bytes
    vols="${1-}"
    [[ -n "${vols}" ]] || vols='[]'
    sizes='{}'
    while IFS=$'\t' read -r name path; do
        [[ -n "${name}" && -n "${path}" ]] || continue
        out="$(cockpit-volumes-list-du "${path}")" || true
        bytes="${out%%[[:space:]]*}"
        [[ "${bytes}" =~ ^[0-9]+$ ]] || continue
        sizes="$(jq -c -n --argjson s "${sizes}" --arg name "${name}" --argjson bytes "${bytes}" '$s + {($name): $bytes}')" || return 1
    done < <(printf '%s' "${vols}" | jq -r '.[]? | [(.Name // ""), (.Mountpoint // "")] | @tsv' 2>/dev/null)
    printf '%s\n' "${sizes}"
}

# @description: Prints the source map for volumes created by Quadlet .volume files.
# @details:
#   Every *.volume file in the installed-quadlet directory, or one bundle folder below it, gives
#   {source:quadlet, unit:<base>-volume.service, unit_state, file, app} under the volume name from
#   cockpit-volumes-quadlet-name. app is set only for files in a bundle folder. When two files
#   create the same volume, the first one in sorted path order wins.
# @stdout: one JSON object mapping a volume name to its source entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-volumes-list-sources() {
    local sources dir file base name unit info state app text
    sources='{}'
    dir="$(cockpit-volumes-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            base="${file##*/}"
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            name="$(cockpit-volumes-quadlet-name "${base}" "${text}")" || continue
            unit="${base%.volume}-volume.service"
            info="$(cockpit-volumes-list-unit-info "${unit}")"
            state="${info%%$'\t'*}"
            app="$(cockpit-volumes-list-app "${file}" "${dir}")"
            sources="$(jq -c -n --argjson s "${sources}" --arg name "${name}" --arg unit "${unit}" \
                --arg state "${state}" --arg file "$(cockpit-volumes-list-display-path "${file}")" --arg app "${app}" \
                'if $s[$name] then $s else $s + {($name): ({source: "quadlet", unit: $unit, unit_state: $state, file: $file}
                    + (if $app == "" then {} else {app: $app} end))} end')" || return 1
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.volume' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    printf '%s\n' "${sources}"
}

# @description: Prints the state, file and app of every systemd unit named by a container label.
# @details:
#   The units are the PODMAN_SYSTEMD_UNIT labels of the containers. The file is shown as ~/...,
#   and app is set when the file is in a bundle folder of the installed-quadlet directory.
# @arg: $1 - JSON array of containers.
# @stdout: one JSON object mapping a unit name to {unit_state, file, app}.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-volumes-list-units() {
    local ctrs units dir unit info state file app
    ctrs="${1-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    units='{}'
    dir="$(cockpit-volumes-list-quadlet-dir)"
    while IFS= read -r unit; do
        [[ -n "${unit}" ]] || continue
        info="$(cockpit-volumes-list-unit-info "${unit}")"
        state="${info%%$'\t'*}"
        file="${info#*$'\t'}"
        app="$(cockpit-volumes-list-app "${file}" "${dir}")"
        units="$(jq -c -n --argjson u "${units}" --arg unit "${unit}" --arg state "${state}" \
            --arg file "$(cockpit-volumes-list-display-path "${file}")" --arg app "${app}" \
            '$u + {($unit): ({unit_state: $state} + (if $file == "" then {} else {file: $file} end)
                + (if $app == "" then {} else {app: $app} end))}')" || return 1
    done < <(printf '%s' "${ctrs}" | jq -r '[.[]? | (.Labels // {}) | objects | .PODMAN_SYSTEMD_UNIT // empty] | unique | .[]' 2>/dev/null)
    printf '%s\n' "${units}"
}

# @description: Lists the podshift user's Podman volumes as resource cards.
# @details:
#   Reads podman volume ls, podman volume inspect, podman ps -a and podman container inspect,
#   measures each mountpoint with du, then finds which volumes come from a Quadlet .volume file
#   and which are mounted by a container with a systemd unit. The items are built by
#   cockpit-volumes-items. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-volumes-list() {
    local vols ctrs sources units sizes
    vols="$(cockpit-volumes-list-inspect)" || return 1
    [[ -n "${vols}" ]] || vols='[]'
    ctrs="$(cockpit-volumes-list-containers)" || return 1
    sources="$(cockpit-volumes-list-sources)" || return 1
    units="$(cockpit-volumes-list-units "${ctrs}")" || return 1
    sizes="$(cockpit-volumes-list-sizes "${vols}")" || return 1
    cockpit-volumes-items "${vols}" "${ctrs}" "${sources}" "${units}" "${sizes}" "${HOME:-}"
}
