#!/usr/bin/env bash
# @file: cockpit-drop-history-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/drop
# @dest-dir: /opt/podshift/cockpit/api/fn/drop
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the latest status of each drop from podshift-drop-history journal records.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {readable: true, items} from journalctl -o json output of the drop history tag.
# @details:
#   Reads journalctl -o json lines from stdin. Only entries with SYSLOG_IDENTIFIER
#   podshift-drop-history whose MESSAGE is a JSON object with a drop ID (a UUIDv7), a name and a
#   drop status (accepted, validated, installing, installed, unchanged, failed or refused) are used
#   (log-drop-history writes them); other records, such as older ones without an ID, are skipped.
#   Records are grouped by drop ID, so dropping the same file twice gives two items. Each item is
#   the newest record of its drop: {id, name, status, time} plus reason when that record has one,
#   and description, the newest non-empty Description of that drop. time is
#   __REALTIME_TIMESTAMP as UTC ISO 8601, to the second. Items are newest first, at most the given
#   count (100 by default). name is cut to 255 characters, reason and description to 200.
# @arg: $1 - optional maximum number of items, 100 by default.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 when the count is not a number or jq fails.
cockpit-drop-history-items() {
    local max
    max="${1:-100}"
    [[ "${max}" =~ ^[0-9]+$ && "${max}" -gt 0 ]] || return 1
    jq -R -n -c --argjson max "${max}" '
        def num: if type == "number" then . elif type == "string" and test("^[0-9]+$") then tonumber else null end;
        def str: type == "string" and length > 0;
        def uuid7: type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$");
        [ inputs | select(startswith("{")) | (try fromjson catch empty) | objects
          | select(.SYSLOG_IDENTIFIER == "podshift-drop-history")
          | {t: (((.__REALTIME_TIMESTAMP | num) // 0)), m: (.MESSAGE | if type == "string" then (try fromjson catch null) else null end)}
          | select((.m | type) == "object")
          | select((.m.id | uuid7) and (.m.name | str) and (.m.status | IN("accepted", "validated", "installing", "installed", "unchanged", "failed", "refused")))
        ]
        | to_entries | map(.value + {i: .key})
        | group_by(.m.id)
        | map(
            sort_by([.t, .i]) as $records
            | $records[-1] as $last
            | ([$records[] | .m.description | select(str)] | last) as $description
            | {id: $last.m.id, name: $last.m.name[0:255], status: $last.m.status, time: ($last.t / 1000000 | floor | todate)}
            + (if ($last.m.reason | str) then {reason: $last.m.reason[0:200]} else {} end)
            + (if $description == null then {} else {description: $description[0:200]} end)
            + {t: $last.t, i: $last.i}
        )
        | sort_by([.t, .i]) | reverse | .[0:$max] | map(del(.t, .i))
        | {readable: true, items: .}
    ' 2>/dev/null
}
