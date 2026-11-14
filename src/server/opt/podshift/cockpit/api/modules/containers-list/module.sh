#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Containers list module: lists the podshift user's Podman containers as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7C2E91A4D05B:-}" ]]; then
    DIR_7C2E91A4D05B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7C2E91A4D05B
fi

# shellcheck source=../../fn/resources/cockpit-containers-items.sh
declare -F cockpit-containers-items >/dev/null || source "${DIR_7C2E91A4D05B}/../../fn/resources/cockpit-containers-items.sh"
# shellcheck source=../../fn/overview/cockpit-overview-quadlet-unit.sh
declare -F cockpit-overview-quadlet-unit >/dev/null || source "${DIR_7C2E91A4D05B}/../../fn/overview/cockpit-overview-quadlet-unit.sh"

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-containers-list-podman() {
    podman "$@"
}

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments after --user.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code, or 1 when systemctl is missing.
cockpit-containers-list-systemctl() {
    systemctl --user "$@"
}

# @description: Prints one podman stats sample for the given containers, limited to 5 seconds.
# @details:
#   Runs podman stats --no-stream --format json. Nothing usable is printed on a timeout or an
#   error; callers then leave CPU and Memory out.
# @arg: $@ - container IDs.
# @stdout: podman stats JSON, or nothing.
# @exitcode: the podman exit code; callers use the output, not the code.
cockpit-containers-list-stats() {
    if command -v timeout >/dev/null 2>&1; then
        timeout 5 podman stats --no-stream --format json -- "$@" 2>/dev/null
    else
        podman stats --no-stream --format json -- "$@" 2>/dev/null
    fi
}

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-containers-list-quadlet-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_7C2E91A4D05B}/../../../../fn/load-podshift-conf-main.sh"
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
cockpit-containers-list-display-path() {
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
cockpit-containers-list-app() {
    local file dir parent
    file="${1-}"
    dir="${2-}"
    dir="${dir%/}"
    [[ -n "${file}" && -n "${dir}" && "${file}" == "${dir}/"*/* ]] || return 0
    parent="${file%/*}"
    [[ "${parent%/*}" == "${dir}" ]] || return 0
    # shellcheck source=../../../../fn/quadlet/get-app-name.sh
    declare -F get-app-name >/dev/null || source "${DIR_7C2E91A4D05B}/../../../../fn/quadlet/get-app-name.sh"
    get-app-name "${parent##*/}"
    return 0
}

# @description: Prints the ActiveState, LoadState and source file of one systemd user unit.
# @details:
#   The file is SourcePath (the Quadlet file for a generated unit), else FragmentPath. Values that
#   cannot be read are left empty.
# @arg: $1 - unit name.
# @stdout: one line, <state><TAB><load state><TAB><file>.
# @exitcode: 0 always.
cockpit-containers-list-unit-info() {
    local out line state load source fragment
    out="$(cockpit-containers-list-systemctl show -p ActiveState -p LoadState -p SourcePath -p FragmentPath -- "${1-}" 2>/dev/null)" || out=""
    state=""
    load=""
    source=""
    fragment=""
    while IFS= read -r line; do
        case "${line}" in
            ActiveState=*) state="${line#ActiveState=}" ;;
            LoadState=*) load="${line#LoadState=}" ;;
            SourcePath=*) source="${line#SourcePath=}" ;;
            FragmentPath=*) fragment="${line#FragmentPath=}" ;;
        esac
    done <<< "${out}"
    printf '%s\t%s\t%s\n' "${state}" "${load}" "${source:-${fragment}}"
    return 0
}

# @description: Prints podman ps -a JSON for every container of the current (podshift) user.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-containers-list-ps() {
    local raw
    raw="$(cockpit-containers-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    printf '%s\n' "${raw}"
}

# @description: Prints podman container inspect JSON for every container in a podman ps array, in one call.
# @arg: $1 - JSON array from podman ps -a --format json.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-containers-list-inspect() {
    local raw out
    local -a ids
    raw="${1-}"
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    out="$(cockpit-containers-list-podman container inspect -- "${ids[@]}" 2>/dev/null)" || return 1
    [[ -n "${out}" ]] || out='[]'
    printf '%s\n' "${out}"
}

# @description: Prints one podman stats sample for the running containers in a podman ps array.
# @details:
#   Only containers in the running state are sampled. A failed or timed-out sample, or output that
#   is not a JSON array, gives [], so CPU and Memory are left out.
# @arg: $1 - JSON array from podman ps -a --format json.
# @stdout: one JSON array.
# @exitcode: 0 always.
cockpit-containers-list-usage() {
    local raw out
    local -a ids
    raw="${1-}"
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | select(((.State // "") | ascii_downcase) == "running") | (.Id // .ID // empty)] | unique | .[]' 2>/dev/null)
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    out="$(cockpit-containers-list-stats "${ids[@]}")" || true
    if printf '%s' "${out}" | jq -e 'type == "array"' >/dev/null 2>&1; then
        printf '%s\n' "${out}"
    else
        printf '[]\n'
    fi
    return 0
}

# @description: Prints the unit map for containers run by Quadlet .container files.
# @details:
#   Every *.container file in the installed-quadlet directory, or one bundle folder below it,
#   gives {file, app} under its generated unit name from cockpit-overview-quadlet-unit. app is set
#   only for files in a bundle folder. When two files give the same unit, the first one in sorted
#   path order wins.
# @stdout: one JSON object mapping a unit name to its Quadlet file entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-containers-list-quadlets() {
    local quadlets dir file unit app
    quadlets='{}'
    dir="$(cockpit-containers-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            unit="$(cockpit-overview-quadlet-unit "${file}")" || continue
            app="$(cockpit-containers-list-app "${file}" "${dir}")"
            quadlets="$(jq -c -n --argjson q "${quadlets}" --arg unit "${unit}" \
                --arg file "$(cockpit-containers-list-display-path "${file}")" --arg app "${app}" \
                'if $q[$unit] then $q else $q + {($unit): ({file: $file} + (if $app == "" then {} else {app: $app} end))} end')" || return 1
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.container' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    printf '%s\n' "${quadlets}"
}

# @description: Prints the state, load state, file and app of every systemd unit named by a container label.
# @details:
#   The units are the PODMAN_SYSTEMD_UNIT labels of the containers. The file is shown as ~/...,
#   and app is set when the file is in a bundle folder of the installed-quadlet directory.
# @arg: $1 - JSON array from podman ps -a --format json.
# @stdout: one JSON object mapping a unit name to {unit_state, load_state, file, app}.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-containers-list-units() {
    local ctrs units dir unit info state load file app
    ctrs="${1-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    units='{}'
    dir="$(cockpit-containers-list-quadlet-dir)"
    while IFS= read -r unit; do
        [[ -n "${unit}" ]] || continue
        info="$(cockpit-containers-list-unit-info "${unit}")"
        state="${info%%$'\t'*}"
        info="${info#*$'\t'}"
        load="${info%%$'\t'*}"
        file="${info#*$'\t'}"
        app="$(cockpit-containers-list-app "${file}" "${dir}")"
        units="$(jq -c -n --argjson u "${units}" --arg unit "${unit}" --arg state "${state}" --arg load "${load}" \
            --arg file "$(cockpit-containers-list-display-path "${file}")" --arg app "${app}" \
            '$u + {($unit): ({unit_state: $state, load_state: $load} + (if $file == "" then {} else {file: $file} end)
                + (if $app == "" then {} else {app: $app} end))}')" || return 1
    done < <(printf '%s' "${ctrs}" | jq -r '[.[]? | (.Labels // {}) | objects | .PODMAN_SYSTEMD_UNIT // empty] | unique | .[]' 2>/dev/null)
    printf '%s\n' "${units}"
}

# @description: Lists the podshift user's Podman containers as resource cards.
# @details:
#   Reads podman ps -a, one batched podman container inspect and one podman stats sample of the
#   running containers (5 seconds at most), then finds which containers a Quadlet .container file
#   or another systemd unit runs. The items are built by cockpit-containers-items. The process runs
#   in the podshift session, so podman and systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-containers-list() {
    local ps inspect quadlets units stats
    ps="$(cockpit-containers-list-ps)" || return 1
    inspect="$(cockpit-containers-list-inspect "${ps}")" || return 1
    quadlets="$(cockpit-containers-list-quadlets)" || return 1
    units="$(cockpit-containers-list-units "${ps}")" || return 1
    stats="$(cockpit-containers-list-usage "${ps}")"
    cockpit-containers-items "${ps}" "${inspect}" "${quadlets}" "${units}" "${stats}" "${HOME:-}"
}
