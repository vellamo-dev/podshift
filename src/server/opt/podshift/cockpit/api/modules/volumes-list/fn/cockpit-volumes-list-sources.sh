#!/usr/bin/env bash
# @file: cockpit-volumes-list-sources.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the source map for volumes created by Quadlet .volume files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8ADD95513E81:-}" ]]; then
    DIR_8ADD95513E81="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8ADD95513E81
fi

# @description: Prints the source map for volumes created by Quadlet .volume files.
# @details:
#   Every *.volume file in the installed-quadlet directory, or one bundle folder below it, gives
#   {source:quadlet, unit:<base>-volume.service, unit_state, file, app} under the volume name from
#   cockpit-volumes-quadlet-name. app is set only for files in a bundle folder. When two files
#   create the same volume, the first one in sorted path order wins. The unit states come from one
#   systemctl show call (cockpit-units-info) and the map from one jq call.
# @stdout: one JSON object mapping a volume name to its source entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-volumes-list-sources() {
    local dir file base name text info state tsv i
    local -a files names units
    # shellcheck source=./cockpit-volumes-list-quadlet-dir.sh
    declare -F cockpit-volumes-list-quadlet-dir >/dev/null || source "${DIR_8ADD95513E81}/cockpit-volumes-list-quadlet-dir.sh"
    # shellcheck source=../../../fn/resources/cockpit-volumes-quadlet-name.sh
    declare -F cockpit-volumes-quadlet-name >/dev/null || source "${DIR_8ADD95513E81}/../../../fn/resources/cockpit-volumes-quadlet-name.sh"
    # shellcheck source=./cockpit-volumes-list-display-path.sh
    declare -F cockpit-volumes-list-display-path >/dev/null || source "${DIR_8ADD95513E81}/cockpit-volumes-list-display-path.sh"
    # shellcheck source=./cockpit-volumes-list-app.sh
    declare -F cockpit-volumes-list-app >/dev/null || source "${DIR_8ADD95513E81}/cockpit-volumes-list-app.sh"
    # shellcheck source=./cockpit-volumes-list-systemctl.sh
    declare -F cockpit-volumes-list-systemctl >/dev/null || source "${DIR_8ADD95513E81}/cockpit-volumes-list-systemctl.sh"
    # shellcheck source=../../../fn/resources/cockpit-units-info.sh
    declare -F cockpit-units-info >/dev/null || source "${DIR_8ADD95513E81}/../../../fn/resources/cockpit-units-info.sh"
    files=()
    names=()
    units=()
    dir="$(cockpit-volumes-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            base="${file##*/}"
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            name="$(cockpit-volumes-quadlet-name "${base}" "${text}")" || continue
            files+=("${file}")
            names+=("${name}")
            units+=("${base%.volume}-volume.service")
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.volume' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    tsv=""
    i=0
    while IFS= read -r info; do
        info="${info#*$'\t'}"
        state="${info%%$'\t'*}"
        tsv+="${names[i]}"$'\t'"${units[i]}"$'\t'"${state}"$'\t'"$(cockpit-volumes-list-display-path "${files[i]}")"
        tsv+=$'\t'"$(cockpit-volumes-list-app "${files[i]}" "${dir}")"$'\n'
        i=$((i + 1))
    done < <(cockpit-units-info cockpit-volumes-list-systemctl "${units[@]}")
    printf '%s' "${tsv}" | jq -R -n -c '
        reduce (inputs | split("\t")) as [$name, $unit, $state, $file, $app] ({};
            if .[$name] then . else . + {($name): ({source: "quadlet", unit: $unit, unit_state: $state, file: $file}
                + (if $app == "" then {} else {app: $app} end))} end)'
}
