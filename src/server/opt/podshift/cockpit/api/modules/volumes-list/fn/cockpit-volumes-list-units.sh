#!/usr/bin/env bash
# @file: cockpit-volumes-list-units.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the state, file and app of every systemd unit named by a container label.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1F06B6CC5865:-}" ]]; then
    DIR_1F06B6CC5865="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1F06B6CC5865
fi

# @description: Prints the state, file and app of every systemd unit named by a container label.
# @details:
#   The units are the PODMAN_SYSTEMD_UNIT labels of the containers, read with one systemctl show
#   call (cockpit-units-info). The file is shown as ~/..., and app is set when the file is in a
#   bundle folder of the installed-quadlet directory. The map is built with one jq call.
# @arg: $1 - JSON array of containers.
# @stdout: one JSON object mapping a unit name to {unit_state, file, app}.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-volumes-list-units() {
    local ctrs dir info unit state file tsv
    local -a units
    # shellcheck source=./cockpit-volumes-list-quadlet-dir.sh
    declare -F cockpit-volumes-list-quadlet-dir >/dev/null || source "${DIR_1F06B6CC5865}/cockpit-volumes-list-quadlet-dir.sh"
    # shellcheck source=./cockpit-volumes-list-display-path.sh
    declare -F cockpit-volumes-list-display-path >/dev/null || source "${DIR_1F06B6CC5865}/cockpit-volumes-list-display-path.sh"
    # shellcheck source=./cockpit-volumes-list-app.sh
    declare -F cockpit-volumes-list-app >/dev/null || source "${DIR_1F06B6CC5865}/cockpit-volumes-list-app.sh"
    # shellcheck source=./cockpit-volumes-list-systemctl.sh
    declare -F cockpit-volumes-list-systemctl >/dev/null || source "${DIR_1F06B6CC5865}/cockpit-volumes-list-systemctl.sh"
    # shellcheck source=../../../fn/resources/cockpit-units-info.sh
    declare -F cockpit-units-info >/dev/null || source "${DIR_1F06B6CC5865}/../../../fn/resources/cockpit-units-info.sh"
    ctrs="${1-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    dir="$(cockpit-volumes-list-quadlet-dir)"
    mapfile -t units < <(printf '%s' "${ctrs}" | jq -r '[.[]? | (.Labels // {}) | objects | .PODMAN_SYSTEMD_UNIT // empty] | unique | .[] | select(. != "")' 2>/dev/null)
    tsv=""
    while IFS= read -r info; do
        unit="${info%%$'\t'*}"
        info="${info#*$'\t'}"
        state="${info%%$'\t'*}"
        file="${info##*$'\t'}"
        tsv+="${unit}"$'\t'"${state}"$'\t'"$(cockpit-volumes-list-display-path "${file}")"
        tsv+=$'\t'"$(cockpit-volumes-list-app "${file}" "${dir}")"$'\n'
    done < <(cockpit-units-info cockpit-volumes-list-systemctl "${units[@]}")
    printf '%s' "${tsv}" | jq -R -n -c '
        reduce (inputs | split("\t")) as [$unit, $state, $file, $app] ({};
            . + {($unit): ({unit_state: $state} + (if $file == "" then {} else {file: $file} end)
                + (if $app == "" then {} else {app: $app} end))})'
}
