#!/usr/bin/env bash
# @file: cockpit-containers-list-units.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the state, load state, file and app of every systemd unit named by a container label.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B11A06EAEDF5:-}" ]]; then
    DIR_B11A06EAEDF5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B11A06EAEDF5
fi

# @description: Prints the state, load state, file and app of every systemd unit named by a container label.
# @details:
#   The units are the PODMAN_SYSTEMD_UNIT labels of the containers, read with one systemctl show
#   call (cockpit-units-info). The file is shown as ~/..., and app is set when the file is in a
#   bundle folder of the installed-quadlet directory. The map is built with one jq call.
# @arg: $1 - JSON array from podman ps -a --format json.
# @stdout: one JSON object mapping a unit name to {unit_state, load_state, file, app}.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-containers-list-units() {
    local ctrs dir info unit state load file tsv
    local -a units
    # shellcheck source=./cockpit-containers-list-quadlet-dir.sh
    declare -F cockpit-containers-list-quadlet-dir >/dev/null || source "${DIR_B11A06EAEDF5}/cockpit-containers-list-quadlet-dir.sh"
    # shellcheck source=./cockpit-containers-list-display-path.sh
    declare -F cockpit-containers-list-display-path >/dev/null || source "${DIR_B11A06EAEDF5}/cockpit-containers-list-display-path.sh"
    # shellcheck source=./cockpit-containers-list-app.sh
    declare -F cockpit-containers-list-app >/dev/null || source "${DIR_B11A06EAEDF5}/cockpit-containers-list-app.sh"
    # shellcheck source=./cockpit-containers-list-systemctl.sh
    declare -F cockpit-containers-list-systemctl >/dev/null || source "${DIR_B11A06EAEDF5}/cockpit-containers-list-systemctl.sh"
    # shellcheck source=../../../fn/resources/cockpit-units-info.sh
    declare -F cockpit-units-info >/dev/null || source "${DIR_B11A06EAEDF5}/../../../fn/resources/cockpit-units-info.sh"
    ctrs="${1-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    dir="$(cockpit-containers-list-quadlet-dir)"
    mapfile -t units < <(printf '%s' "${ctrs}" | jq -r '[.[]? | (.Labels // {}) | objects | .PODMAN_SYSTEMD_UNIT // empty] | unique | .[] | select(. != "")' 2>/dev/null)
    tsv=""
    while IFS= read -r info; do
        unit="${info%%$'\t'*}"
        info="${info#*$'\t'}"
        state="${info%%$'\t'*}"
        info="${info#*$'\t'}"
        load="${info%%$'\t'*}"
        file="${info#*$'\t'}"
        tsv+="${unit}"$'\t'"${state}"$'\t'"${load}"$'\t'"$(cockpit-containers-list-display-path "${file}")"
        tsv+=$'\t'"$(cockpit-containers-list-app "${file}" "${dir}")"$'\n'
    done < <(cockpit-units-info cockpit-containers-list-systemctl "${units[@]}")
    printf '%s' "${tsv}" | jq -R -n -c '
        reduce (inputs | split("\t")) as [$unit, $state, $load, $file, $app] ({};
            . + {($unit): ({unit_state: $state, load_state: $load} + (if $file == "" then {} else {file: $file} end)
                + (if $app == "" then {} else {app: $app} end))})'
}
