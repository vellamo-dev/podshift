#!/usr/bin/env bash
# @file: cockpit-networks-list-sources.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the source map for networks created by Quadlet files or user services.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F69896B65604:-}" ]]; then
    DIR_F69896B65604="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F69896B65604
fi

# @description: Prints the source map for networks created by Quadlet files or user services.
# @details:
#   Quadlet: every *.network file in the installed-quadlet directory, or one bundle folder below
#   it, gives {source:quadlet, unit:<base>-network.service, unit_state, file, app}. app is set
#   only for files in a bundle folder. Unit: every *.service file in ~/.config/systemd/user with
#   podman network create <name> gives {source:unit, unit, unit_state, file}. A Quadlet entry
#   wins over a unit entry with the same name. The unit states come from one systemctl show call
#   (cockpit-units-info) and the map from one jq call.
# @stdout: one JSON object mapping a network name to its source entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-networks-list-sources() {
    local dir file base parent app name unit text info tsv i
    local -a kinds names units files apps states
    # shellcheck source=./cockpit-networks-list-quadlet-dir.sh
    declare -F cockpit-networks-list-quadlet-dir >/dev/null || source "${DIR_F69896B65604}/cockpit-networks-list-quadlet-dir.sh"
    # shellcheck source=../../../fn/resources/cockpit-networks-quadlet-name.sh
    declare -F cockpit-networks-quadlet-name >/dev/null || source "${DIR_F69896B65604}/../../../fn/resources/cockpit-networks-quadlet-name.sh"
    # shellcheck source=./cockpit-networks-list-user-unit-dir.sh
    declare -F cockpit-networks-list-user-unit-dir >/dev/null || source "${DIR_F69896B65604}/cockpit-networks-list-user-unit-dir.sh"
    # shellcheck source=../../../fn/resources/cockpit-networks-unit-networks.sh
    declare -F cockpit-networks-unit-networks >/dev/null || source "${DIR_F69896B65604}/../../../fn/resources/cockpit-networks-unit-networks.sh"
    # shellcheck source=./cockpit-networks-list-systemctl.sh
    declare -F cockpit-networks-list-systemctl >/dev/null || source "${DIR_F69896B65604}/cockpit-networks-list-systemctl.sh"
    # shellcheck source=../../../fn/resources/cockpit-units-info.sh
    declare -F cockpit-units-info >/dev/null || source "${DIR_F69896B65604}/../../../fn/resources/cockpit-units-info.sh"
    # shellcheck source=./cockpit-networks-list-display-path.sh
    declare -F cockpit-networks-list-display-path >/dev/null || source "${DIR_F69896B65604}/cockpit-networks-list-display-path.sh"
    kinds=()
    names=()
    units=()
    files=()
    apps=()
    dir="$(cockpit-networks-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            base="${file##*/}"
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            name="$(cockpit-networks-quadlet-name "${base}" "${text}")" || continue
            parent="${file%/*}"
            app=""
            if [[ "${parent}" != "${dir%/}" ]]; then
                # shellcheck source=../../../../../fn/quadlet/get-app-name.sh
                declare -F get-app-name >/dev/null || source "${DIR_F69896B65604}/../../../../../fn/quadlet/get-app-name.sh"
                app="$(get-app-name "${parent##*/}")"
            fi
            kinds+=("quadlet")
            names+=("${name}")
            units+=("${base%.network}-network.service")
            files+=("${file}")
            apps+=("${app}")
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.network' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    dir="$(cockpit-networks-list-user-unit-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            [[ "${text}" == *"network create"* ]] || continue
            while IFS= read -r name; do
                [[ -n "${name}" ]] || continue
                kinds+=("unit")
                names+=("${name}")
                units+=("${file##*/}")
                files+=("${file}")
                apps+=("")
            done < <(cockpit-networks-unit-networks "${text}")
        done < <(find -P "${dir}" -maxdepth 1 -type f -name '*.service' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    states=()
    while IFS= read -r info; do
        info="${info#*$'\t'}"
        states+=("${info%%$'\t'*}")
    done < <(cockpit-units-info cockpit-networks-list-systemctl "${units[@]}")
    tsv=""
    for (( i = 0; i < ${#names[@]}; i++ )); do
        tsv+="${kinds[i]}"$'\t'"${names[i]}"$'\t'"${units[i]}"$'\t'"${states[i]-}"
        tsv+=$'\t'"$(cockpit-networks-list-display-path "${files[i]}")"$'\t'"${apps[i]}"$'\n'
    done
    # A Quadlet entry replaces an earlier one; a unit entry is added only for a new name.
    printf '%s' "${tsv}" | jq -R -n -c '
        reduce (inputs | split("\t")) as [$kind, $name, $unit, $state, $file, $app] ({};
            if $kind == "quadlet" then
                . + {($name): ({source: "quadlet", unit: $unit, unit_state: $state, file: $file}
                    + (if $app == "" then {} else {app: $app} end))}
            elif .[$name] then .
            else . + {($name): {source: "unit", unit: $unit, unit_state: $state, file: $file}} end)'
}
