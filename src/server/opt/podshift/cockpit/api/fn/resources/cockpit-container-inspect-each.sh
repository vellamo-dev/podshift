#!/usr/bin/env bash
# @file: cockpit-container-inspect-each.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman container inspect JSON for the given IDs, one by one when the call for all of them fails.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Inspects all IDs in one call, and when that fails, each ID on its own, keeping the ones that work.
# @details:
#   One broken container, such as one Podman can no longer inspect, makes the call for all IDs
#   fail. The one-by-one pass then leaves only that container out, so a list action still works.
#   Podman runs through the given function, the module's podman wrapper that the tests replace. A
#   failed ID is logged with logger -t podshift-api, with the first line of its podman error.
# @arg: $1 - name of the function that runs podman.
# @arg: $@ - from $2 on, the container IDs.
# @stdout: one JSON array of inspect objects, [] when there is none or none could be read.
# @exitcode: 0 always.
cockpit-container-inspect-each() {
    local runner out id one err
    local -a ids parts
    runner="${1-}"
    ids=("${@:2}")
    if (( ${#ids[@]} == 0 )); then
        printf '[]\n'
        return 0
    fi
    if out="$("${runner}" container inspect -- "${ids[@]}" 2>/dev/null)" && [[ -n "${out}" ]]; then
        printf '%s\n' "${out}"
        return 0
    fi
    parts=()
    err="$(mktemp 2>/dev/null)" || err="/dev/null"
    for id in "${ids[@]}"; do
        if one="$("${runner}" container inspect -- "${id}" 2>"${err}")" && [[ -n "${one}" ]]; then
            parts+=("${one}")
        else
            logger -t podshift-api -p warn "container inspect failed for ${id:0:12}: $(head -n 1 "${err}" 2>/dev/null | LC_ALL=C tr -c '[:print:]' ' ' | cut -c1-200)" 2>/dev/null || true
        fi
    done
    [[ "${err}" == "/dev/null" ]] || rm -f -- "${err}"
    if (( ${#parts[@]} == 0 )); then
        printf '[]\n'
        return 0
    fi
    printf '%s\n' "${parts[@]}" | jq -c -s 'map(.[]?)' 2>/dev/null || printf '[]\n'
    return 0
}
