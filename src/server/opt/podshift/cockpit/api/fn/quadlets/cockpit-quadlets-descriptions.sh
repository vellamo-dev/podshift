#!/usr/bin/env bash
# @file: cockpit-quadlets-descriptions.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/quadlets
# @dest-dir: /opt/podshift/cockpit/api/fn/quadlets
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Builds a JSON object of path to Description for the paths in a quadlet ls listing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_93745BC220DC:-}" ]]; then
    DIR_93745BC220DC="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_93745BC220DC
fi

# @description: Builds a JSON object of path to Description for the paths in a quadlet ls listing.
# @details:
#   Paths are taken from the Path field of each object in the listing. Missing, unreadable or
#   description-less files map to an empty string. An invalid listing becomes {}. The pairs are
#   passed to one jq call as positional arguments, so a tab or quote in a description is kept.
# @arg: $1 - JSON array from podman quadlet ls --format json, or null, or empty for none.
# @stdout: one JSON object mapping each path to its Description string.
# @exitcode: 0
cockpit-quadlets-descriptions() {
    local raw paths path
    local -a pairs
    raw="${1-}"
    [[ -n "${raw}" ]] || raw='[]'
    paths="$(jq -c '
        if . == null then []
        elif type != "array" then []
        else
            [.[] | objects | (.Path // empty) | select(type == "string" and . != "")] | unique
        end
    ' <<< "${raw}" 2>/dev/null)" || paths='[]'
    # shellcheck source=./cockpit-quadlets-unit-description.sh
    declare -F cockpit-quadlets-unit-description >/dev/null || source "${DIR_93745BC220DC}/cockpit-quadlets-unit-description.sh"
    pairs=()
    while IFS= read -r path; do
        [[ -n "${path}" ]] || continue
        pairs+=("${path}" "$(cockpit-quadlets-unit-description "${path}")")
    done < <(jq -r '.[]' <<< "${paths}")
    jq -n -c '[$ARGS.positional | _nwise(2) | {(.[0]): .[1]}] | add // {}' --args "${pairs[@]}" 2>/dev/null || printf '{}\n'
}
