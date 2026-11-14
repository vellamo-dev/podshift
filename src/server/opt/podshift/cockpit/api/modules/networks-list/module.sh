#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Networks list module: lists the podshift user's Podman networks as resource cards.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4C8A1E6F2B93:-}" ]]; then
    DIR_4C8A1E6F2B93="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4C8A1E6F2B93
fi

# shellcheck source=../../fn/resources/cockpit-networks-items.sh
declare -F cockpit-networks-items >/dev/null || source "${DIR_4C8A1E6F2B93}/../../fn/resources/cockpit-networks-items.sh"
# shellcheck source=../../fn/resources/cockpit-networks-quadlet-name.sh
declare -F cockpit-networks-quadlet-name >/dev/null || source "${DIR_4C8A1E6F2B93}/../../fn/resources/cockpit-networks-quadlet-name.sh"
# shellcheck source=../../fn/resources/cockpit-networks-unit-networks.sh
declare -F cockpit-networks-unit-networks >/dev/null || source "${DIR_4C8A1E6F2B93}/../../fn/resources/cockpit-networks-unit-networks.sh"

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-networks-list-podman() {
    podman "$@"
}

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments after --user.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code, or 1 when systemctl is missing.
cockpit-networks-list-systemctl() {
    systemctl --user "$@"
}

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-networks-list-quadlet-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_4C8A1E6F2B93}/../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    if [[ -n "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        printf '%s\n' "${PODSHIFT_PODMAN_QUADLETS_DIR}"
    fi
}

# @description: Prints the systemd user unit directory of the current (podshift) user.
# @stdout: the directory path, or nothing when HOME is not set.
# @exitcode: 0 always.
cockpit-networks-list-user-unit-dir() {
    if [[ -n "${HOME:-}" ]]; then
        printf '%s\n' "${HOME}/.config/systemd/user"
    fi
}

# @description: Prints the ActiveState of one systemd user unit.
# @arg: $1 - unit name.
# @stdout: a state such as active or inactive, or nothing when it cannot be read.
# @exitcode: 0 always.
cockpit-networks-list-unit-state() {
    local state
    if state="$(cockpit-networks-list-systemctl show -p ActiveState --value -- "${1-}" 2>/dev/null)"; then
        printf '%s\n' "${state}"
    fi
    return 0
}

# @description: Shortens a path under HOME to ~/... for display.
# @arg: $1 - path.
# @stdout: the display path.
# @exitcode: 0 always.
cockpit-networks-list-display-path() {
    local path
    path="${1-}"
    if [[ -n "${HOME:-}" && "${path}" == "${HOME}/"* ]]; then
        path="~/${path#"${HOME}/"}"
    fi
    printf '%s\n' "${path}"
}

# @description: Prints podman network inspect JSON for every network of the current (podshift) user.
# @details:
#   Names come from podman network ls --format json. With no networks the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman fails.
cockpit-networks-list-inspect() {
    local raw
    local -a names
    raw="$(cockpit-networks-list-podman network ls --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t names < <(printf '%s' "${raw}" | jq -r '.[]? | (.name // .Name // empty)')
    if [[ "${#names[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    cockpit-networks-list-podman network inspect -- "${names[@]}" 2>/dev/null
}

# @description: Prints the source map for networks created by Quadlet files or user services.
# @details:
#   Quadlet: every *.network file in the installed-quadlet directory, or one bundle folder below
#   it, gives {source:quadlet, unit:<base>-network.service, unit_state, file, app}. app is set
#   only for files in a bundle folder. Unit: every *.service file in ~/.config/systemd/user with
#   podman network create <name> gives {source:unit, unit, unit_state, file}. A Quadlet entry
#   wins over a unit entry with the same name.
# @stdout: one JSON object mapping a network name to its source entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-networks-list-sources() {
    local sources dir file base parent app name unit state text
    sources='{}'
    dir="$(cockpit-networks-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            base="${file##*/}"
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            name="$(cockpit-networks-quadlet-name "${base}" "${text}")" || continue
            unit="${base%.network}-network.service"
            state="$(cockpit-networks-list-unit-state "${unit}")"
            parent="${file%/*}"
            app=""
            if [[ "${parent}" != "${dir%/}" ]]; then
                # shellcheck source=../../../../fn/quadlet/get-app-name.sh
                declare -F get-app-name >/dev/null || source "${DIR_4C8A1E6F2B93}/../../../../fn/quadlet/get-app-name.sh"
                app="$(get-app-name "${parent##*/}")"
            fi
            sources="$(jq -c -n --argjson s "${sources}" --arg name "${name}" --arg unit "${unit}" \
                --arg state "${state}" --arg file "$(cockpit-networks-list-display-path "${file}")" --arg app "${app}" \
                '$s + {($name): ({source: "quadlet", unit: $unit, unit_state: $state, file: $file}
                    + (if $app == "" then {} else {app: $app} end))}')" || return 1
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.network' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    dir="$(cockpit-networks-list-user-unit-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            [[ "${text}" == *"network create"* ]] || continue
            unit="${file##*/}"
            state=""
            while IFS= read -r name; do
                [[ -n "${name}" ]] || continue
                [[ -n "${state}" ]] || state="$(cockpit-networks-list-unit-state "${unit}")"
                sources="$(jq -c -n --argjson s "${sources}" --arg name "${name}" --arg unit "${unit}" \
                    --arg state "${state}" --arg file "$(cockpit-networks-list-display-path "${file}")" \
                    'if $s[$name] then $s else $s + {($name): {source: "unit", unit: $unit, unit_state: $state, file: $file}} end')" || return 1
            done < <(cockpit-networks-unit-networks "${text}")
        done < <(find -P "${dir}" -maxdepth 1 -type f -name '*.service' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    printf '%s\n' "${sources}"
}

# @description: Lists the podshift user's Podman networks as resource cards.
# @details:
#   Reads podman network ls and podman network inspect, then finds which networks come from a
#   Quadlet .network file or a user service with podman network create. The items are built by
#   cockpit-networks-items. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-networks-list() {
    local nets sources
    nets="$(cockpit-networks-list-inspect)" || return 1
    [[ -n "${nets}" ]] || nets='[]'
    sources="$(cockpit-networks-list-sources)" || return 1
    cockpit-networks-items "${nets}" "${sources}"
}
