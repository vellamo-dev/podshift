#!/usr/bin/env bash
# @file: cockpit-images-list-sources.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/images-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/images-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the source map for images pulled by Quadlet .image files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_13CB29AB2F3F:-}" ]]; then
    DIR_13CB29AB2F3F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_13CB29AB2F3F
fi

# @description: Prints the source map for images pulled by Quadlet .image files.
# @details:
#   Every *.image file in the installed-quadlet directory, or one bundle folder below it, gives
#   {source:quadlet, unit:<base>-image.service, unit_state, file, app} under the reference from
#   cockpit-images-quadlet-ref. app is set only for files in a bundle folder. When two files pull
#   the same reference, the first one in sorted path order wins. The unit states come from one
#   systemctl show call (cockpit-units-info) and the map from one jq call.
# @stdout: one JSON object mapping an image reference to its source entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-images-list-sources() {
    local dir file base ref text info state tsv i
    local -a files refs units
    # shellcheck source=./cockpit-images-list-quadlet-dir.sh
    declare -F cockpit-images-list-quadlet-dir >/dev/null || source "${DIR_13CB29AB2F3F}/cockpit-images-list-quadlet-dir.sh"
    # shellcheck source=../../../fn/resources/cockpit-images-quadlet-ref.sh
    declare -F cockpit-images-quadlet-ref >/dev/null || source "${DIR_13CB29AB2F3F}/../../../fn/resources/cockpit-images-quadlet-ref.sh"
    # shellcheck source=./cockpit-images-list-display-path.sh
    declare -F cockpit-images-list-display-path >/dev/null || source "${DIR_13CB29AB2F3F}/cockpit-images-list-display-path.sh"
    # shellcheck source=./cockpit-images-list-app.sh
    declare -F cockpit-images-list-app >/dev/null || source "${DIR_13CB29AB2F3F}/cockpit-images-list-app.sh"
    # shellcheck source=./cockpit-images-list-systemctl.sh
    declare -F cockpit-images-list-systemctl >/dev/null || source "${DIR_13CB29AB2F3F}/cockpit-images-list-systemctl.sh"
    # shellcheck source=../../../fn/resources/cockpit-units-info.sh
    declare -F cockpit-units-info >/dev/null || source "${DIR_13CB29AB2F3F}/../../../fn/resources/cockpit-units-info.sh"
    files=()
    refs=()
    units=()
    dir="$(cockpit-images-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            base="${file##*/}"
            text="$(cat -- "${file}" 2>/dev/null)" || continue
            ref="$(cockpit-images-quadlet-ref "${text}")" || continue
            files+=("${file}")
            refs+=("${ref}")
            units+=("${base%.image}-image.service")
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.image' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    tsv=""
    i=0
    while IFS= read -r info; do
        info="${info#*$'\t'}"
        state="${info%%$'\t'*}"
        tsv+="${refs[i]}"$'\t'"${units[i]}"$'\t'"${state}"$'\t'"$(cockpit-images-list-display-path "${files[i]}")"
        tsv+=$'\t'"$(cockpit-images-list-app "${files[i]}" "${dir}")"$'\n'
        i=$((i + 1))
    done < <(cockpit-units-info cockpit-images-list-systemctl "${units[@]}")
    printf '%s' "${tsv}" | jq -R -n -c '
        reduce (inputs | split("\t")) as [$ref, $unit, $state, $file, $app] ({};
            if .[$ref] then . else . + {($ref): ({source: "quadlet", unit: $unit, unit_state: $state, file: $file}
                + (if $app == "" then {} else {app: $app} end))} end)'
}
