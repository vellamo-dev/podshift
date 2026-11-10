#!/usr/bin/env bash
# @file: cockpit-dispatch-action.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Fixed action map: looks up an action or lists all entries; executes nothing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B6B2B07AEA96:-}" ]]; then
    DIR_B6B2B07AEA96="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B6B2B07AEA96
fi

# @description: Looks up one literal action, or lists every entry, in the fixed dispatch map.
# @details:
#   Module paths come only from this map. Nothing is executed. List and lookup are built from the
#   same entries, in map order.
# @arg: $1 - list, or lookup.
# @arg: $2 - action name when the first argument is lookup.
# @stdout: one JSON object for lookup, or a JSON array for list. Each entry has action, function, directory and realm.
# @exitcode: 0 when the entry or the list was written, 1 when the action is unknown or the mode is not list or lookup.
cockpit-dispatch-action() {
    local mode action directory line collected
    mode="${1:-}"
    action="${2:-}"
    case "${mode}" in
        list|lookup) ;;
        *)
            return 1
            ;;
    esac
    collected=""
    directory="$(CDPATH='' cd -P -- "${DIR_B6B2B07AEA96}/../modules/ping" && pwd -P)" || return 1
    line="$(jq -n -c \
        --arg action ping \
        --arg function cockpit-module-ping \
        --arg directory "${directory}" \
        --arg realm podshift \
        '{action:$action, function:$function, directory:$directory, realm:$realm}')" || return 1
    collected="${collected}${line}"$'\n'
    directory="$(CDPATH='' cd -P -- "${DIR_B6B2B07AEA96}/../modules/capabilities" && pwd -P)" || return 1
    line="$(jq -n -c \
        --arg action capabilities \
        --arg function cockpit-module-capabilities \
        --arg directory "${directory}" \
        --arg realm root \
        '{action:$action, function:$function, directory:$directory, realm:$realm}')" || return 1
    collected="${collected}${line}"$'\n'
    if [[ "${mode}" == "list" ]]; then
        printf '%s' "${collected}" | jq -c -s '.'
        return
    fi
    line="$(printf '%s' "${collected}" | jq -c -s --arg action "${action}" 'map(select(.action == $action)) | if length == 1 then .[0] else empty end')" || return 1
    [[ -n "${line}" ]] || return 1
    printf '%s\n' "${line}"
    return 0
}
