#!/usr/bin/env bash
# @file: cockpit-volumes-list-sizes.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the size in bytes of every volume mountpoint, from du.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_958D6EBC035C:-}" ]]; then
    DIR_958D6EBC035C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_958D6EBC035C
fi

# @description: Prints the size in bytes of every volume mountpoint, from du.
# @details:
#   All volumes share one 5 second budget, so many slow volumes cannot add up to a long wait. Each du
#   gets the time that is left. A volume whose size cannot be read, or that the budget did not
#   reach, is left out of the map. The map is built with one jq call.
# @arg: $1 - JSON array from podman volume inspect.
# @stdout: one JSON object mapping a volume name to its size in bytes.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-volumes-list-sizes() {
    local vols tsv name path out bytes start left
    # shellcheck source=./cockpit-volumes-list-du.sh
    declare -F cockpit-volumes-list-du >/dev/null || source "${DIR_958D6EBC035C}/cockpit-volumes-list-du.sh"
    vols="${1-}"
    [[ -n "${vols}" ]] || vols='[]'
    tsv=""
    start="${SECONDS}"
    while IFS=$'\t' read -r name path; do
        [[ -n "${name}" && -n "${path}" ]] || continue
        left=$(( 5 - (SECONDS - start) ))
        (( left > 0 )) || break
        out="$(cockpit-volumes-list-du "${path}" "${left}")" || true
        bytes="${out%%[[:space:]]*}"
        [[ "${bytes}" =~ ^[0-9]+$ ]] || continue
        tsv+="${name}"$'\t'"${bytes}"$'\n'
    done < <(printf '%s' "${vols}" | jq -r '.[]? | [(.Name // ""), (.Mountpoint // "")] | @tsv' 2>/dev/null)
    printf '%s' "${tsv}" | jq -R -n -c 'reduce (inputs | split("\t")) as [$name, $bytes] ({}; . + {($name): ($bytes | tonumber)})'
}
