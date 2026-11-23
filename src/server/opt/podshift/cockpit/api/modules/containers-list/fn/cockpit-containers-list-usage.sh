#!/usr/bin/env bash
# @file: cockpit-containers-list-usage.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints one podman stats sample for the running containers in a podman ps array.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_90C9EA38FF4E:-}" ]]; then
    DIR_90C9EA38FF4E="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_90C9EA38FF4E
fi

# @description: Prints one podman stats sample for the running containers in a podman ps array.
# @details:
#   Only containers in the running state are sampled. A failed or timed-out sample, or output that
#   is not a JSON array, gives [], so CPU and Memory are left out.
#   The sample gets the seconds left, at most 5; with less than 1 second left, or a value that is
#   not a whole number, it is skipped and [] is printed.
# @arg: $1 - JSON array from podman ps -a --format json.
# @arg: $2 - seconds left for the sample.
# @stdout: one JSON array.
# @exitcode: 0 always.
cockpit-containers-list-usage() {
    local raw seconds out
    local -a ids
    # shellcheck source=./cockpit-containers-list-stats.sh
    declare -F cockpit-containers-list-stats >/dev/null || source "${DIR_90C9EA38FF4E}/cockpit-containers-list-stats.sh"
    raw="${1-}"
    seconds="${2-}"
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | select(((.State // "") | ascii_downcase) == "running") | (.Id // .ID // empty)] | unique | .[]' 2>/dev/null)
    [[ "${seconds}" =~ ^[0-9]+$ ]] || seconds=0
    (( seconds <= 5 )) || seconds=5
    if [[ "${#ids[@]}" -eq 0 || "${seconds}" -lt 1 ]]; then
        printf '[]\n'
        return 0
    fi
    out="$(cockpit-containers-list-stats "${seconds}" "${ids[@]}")" || true
    if printf '%s' "${out}" | jq -e 'type == "array"' >/dev/null 2>&1; then
        printf '%s\n' "${out}"
    else
        printf '[]\n'
    fi
    return 0
}
