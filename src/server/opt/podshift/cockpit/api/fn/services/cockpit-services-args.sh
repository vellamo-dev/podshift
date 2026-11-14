#!/usr/bin/env bash
# @file: cockpit-services-args.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Checks the unit and mode arguments of the service-view, service-logs and quadlet-view actions and prints them.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the unit and mode of a service-view, service-logs or quadlet-view request, or refuses them.
# @details:
#   unit must be 1 to 256 characters that end in .service. Before that suffix only letters, digits,
#   : _ . @ - and systemd escapes such as \x2d are allowed, and it must not start with - or a dot.
#   With mode required (service-view), mode must be unit or status. Without it (service-logs
#   and quadlet-view), a mode argument is refused. The input contract already checks the same, so
#   this is a second check right before systemctl, journalctl or the file read runs.
# @arg: $1 - action arguments as one JSON object, for example {"unit":"web.service","mode":"status"}.
# @arg: $2 - yes when mode is required, no when it must be absent.
# @stdout: unit, a tab and mode (empty for no).
# @exitcode: 0 when all are accepted, 1 otherwise.
cockpit-services-args() {
    local args with_mode unit mode
    args="${1-}"
    with_mode="${2-}"
    # jq -j prints no newline. The x printed after it keeps a trailing newline from being cut off.
    unit="$(printf '%s' "${args}" | jq -j 'if type == "object" and (.unit | type) == "string" then .unit else "" end' 2>/dev/null && printf x)" || return 1
    unit="${unit%x}"
    mode="$(printf '%s' "${args}" | jq -j 'if type != "object" then "?" elif has("mode") | not then "" elif (.mode | type) == "string" then .mode else "?" end' 2>/dev/null && printf x)" || return 1
    mode="${mode%x}"
    [[ -n "${unit}" && "${#unit}" -le 256 ]] || return 1
    [[ "${unit}" =~ ^[A-Za-z0-9:_@]([A-Za-z0-9:_.@-]|\\x[0-9a-f]{2})*\.service$ ]] || return 1
    case "${with_mode}:${mode}" in
        yes:unit|yes:status|no:) ;;
        *) return 1 ;;
    esac
    printf '%s\t%s\n' "${unit}" "${mode}"
    return 0
}
