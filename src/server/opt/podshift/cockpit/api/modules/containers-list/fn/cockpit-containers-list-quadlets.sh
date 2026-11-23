#!/usr/bin/env bash
# @file: cockpit-containers-list-quadlets.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the unit map for containers run by Quadlet .container files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_238FBE83E473:-}" ]]; then
    DIR_238FBE83E473="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_238FBE83E473
fi

# @description: Prints the unit map for containers run by Quadlet .container files.
# @details:
#   Every *.container file in the installed-quadlet directory, or one bundle folder below it,
#   gives {file, app} under its generated unit name from cockpit-overview-quadlet-unit. app is set
#   only for files in a bundle folder. When two files give the same unit, the first one in sorted
#   path order wins. The map is built with one jq call.
# @stdout: one JSON object mapping a unit name to its Quadlet file entry.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-containers-list-quadlets() {
    local dir file unit tsv
    # shellcheck source=./cockpit-containers-list-quadlet-dir.sh
    declare -F cockpit-containers-list-quadlet-dir >/dev/null || source "${DIR_238FBE83E473}/cockpit-containers-list-quadlet-dir.sh"
    # shellcheck source=../../../fn/overview/cockpit-overview-quadlet-unit.sh
    declare -F cockpit-overview-quadlet-unit >/dev/null || source "${DIR_238FBE83E473}/../../../fn/overview/cockpit-overview-quadlet-unit.sh"
    # shellcheck source=./cockpit-containers-list-display-path.sh
    declare -F cockpit-containers-list-display-path >/dev/null || source "${DIR_238FBE83E473}/cockpit-containers-list-display-path.sh"
    # shellcheck source=./cockpit-containers-list-app.sh
    declare -F cockpit-containers-list-app >/dev/null || source "${DIR_238FBE83E473}/cockpit-containers-list-app.sh"
    tsv=""
    dir="$(cockpit-containers-list-quadlet-dir)"
    if [[ -n "${dir}" && -d "${dir}" ]]; then
        # -P: do not follow a symlink when naming the starting directory.
        while IFS= read -r file; do
            [[ -n "${file}" && -r "${file}" ]] || continue
            unit="$(cockpit-overview-quadlet-unit "${file}")" || continue
            tsv+="${unit}"$'\t'"$(cockpit-containers-list-display-path "${file}")"
            tsv+=$'\t'"$(cockpit-containers-list-app "${file}" "${dir}")"$'\n'
        done < <(find -P "${dir}" -maxdepth 2 -type f -name '*.container' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    fi
    printf '%s' "${tsv}" | jq -R -n -c '
        reduce (inputs | split("\t")) as [$unit, $file, $app] ({};
            if .[$unit] then . else . + {($unit): ({file: $file} + (if $app == "" then {} else {app: $app} end))} end)'
}
