#!/usr/bin/env bash
# @file: cockpit-services-log-entries.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the service-logs action data from journalctl -o json lines.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {unit, found: true, readable: true, entries} from journalctl -o json output.
# @details:
#   Reads journalctl -o json output from stdin: one JSON object per line. Lines that are not JSON
#   objects, such as -- No entries --, are skipped. Only the newest entries are kept, at most the
#   given count (100 by default), oldest first. Each entry has time (__REALTIME_TIMESTAMP as UTC
#   ISO 8601, to the second), hostname (_HOSTNAME, or empty), identifier (SYSLOG_IDENTIFIER, else
#   _COMM, else unknown), priority (PRIORITY 0 to 7, 6 when missing) and message (MESSAGE; binary
#   data sent as a byte array is decoded when it can be, else shown as [binary data]). A message
#   longer than 1024 characters is cut to 1024 and ends in an ellipsis, so 100 entries fit in the
#   response. pid (_PID, else SYSLOG_PID) is added when it is a number.
# @arg: $1 - unit name.
# @arg: $2 - optional maximum number of entries, 100 by default.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 when the unit is missing, the count is not a number or jq fails.
cockpit-services-log-entries() {
    local unit max
    unit="${1-}"
    max="${2:-100}"
    [[ -n "${unit}" ]] || return 1
    [[ "${max}" =~ ^[0-9]+$ && "${max}" -gt 0 ]] || return 1
    jq -R -n -c --arg unit "${unit}" --argjson max "${max}" '
        def num: if type == "number" then . elif type == "string" and test("^[0-9]+$") then tonumber else null end;
        def text:
            if type == "string" then .
            elif type == "array" then (try implode catch "[binary data]")
            elif . == null then ""
            else tostring end;
        def cut: if length > 1024 then .[0:1024] + "…" else . end;
        [ inputs | select(startswith("{")) | (try fromjson catch empty) | objects ]
        | .[-$max:]
        | map(
            ((._PID // .SYSLOG_PID) | num) as $pid
            | ((.PRIORITY // "6") | num) as $prio
            | {
                time: (((.__REALTIME_TIMESTAMP | num) // 0) / 1000000 | floor | todate),
                hostname: ((._HOSTNAME // "") | text),
                identifier: ((.SYSLOG_IDENTIFIER // ._COMM // "unknown") | text),
                priority: (if $prio == null or $prio > 7 then 6 else $prio end),
                message: (.MESSAGE | text | cut)
            }
            + (if $pid == null then {} else {pid: $pid} end)
        )
        | {unit: $unit, found: true, readable: true, entries: .}
    ' 2>/dev/null
}
