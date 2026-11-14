#!/usr/bin/env bash
# @file: cockpit-services-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the services-list items from systemctl show text of several user units.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {items:[...]} for the Services tab from systemctl show output, sorted by unit name.
# @details:
#   Reads the output of one systemctl --user show call for several units from stdin: blocks of
#   Key=Value lines, one block per unit, separated by an empty line. Blocks without an Id that
#   ends in .service, or with a LoadState other than loaded, are left out. Each item has id and
#   title (the unit name), subtitle (Description, or the unit name when empty), source (quadlet
#   when SourcePath ends in .container, .pod, .kube, .network, .volume, .image or .build, else
#   unit), activeState, subState, since (StateChangeTimestamp as UTC ISO 8601: a value such as
#   @1731402134 from --timestamp=unix, or "Thu 2026-11-12 09:02:14 UTC"; another form is kept
#   as is; empty when never set), unitFileState and path (FragmentPath, empty when none). These
#   keys are added only when they have a value: preset (UnitFilePreset), quadletFile and
#   quadletKind (SourcePath and its extension, for Quadlet units), mainPid (MainPID above 0),
#   memory (MemoryCurrent in bytes, when set), result (Result other than success) and
#   triggeredBy (TriggeredBy, comma separated).
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when jq fails.
cockpit-services-items() {
    jq -R -s -c '
        def iso:
            if . == null or . == "" or . == "n/a" or . == "0" then ""
            elif test("^@[0-9]+$") then (.[1:] | tonumber | todate)
            elif test("^[A-Z][a-z]{2} [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$") then (.[4:14] + "T" + .[15:23] + "Z")
            else . end;
        def num: if . != null and test("^[0-9]+$") then tonumber else null end;
        def add_if($key; $v): if $v == null or $v == "" then {} else {($key): $v} end;
        [ split("\n\n")[]
          | [ split("\n")[] | select(test("^[A-Za-z]+=")) | capture("^(?<key>[A-Za-z]+)=(?<value>.*)$") ]
          | from_entries
          | select((.Id // "") | test("[.]service$"))
          | select((.LoadState // "loaded") == "loaded")
          | . as $u
          | ((($u.SourcePath // "") | capture("[.](?<kind>container|pod|kube|network|volume|image|build)$") | .kind) // null) as $kind
          | ($u.MainPID | num) as $pid
          | ($u.MemoryCurrent | num) as $mem
          | {
                id: $u.Id,
                title: $u.Id,
                subtitle: (if ($u.Description // "") == "" then $u.Id else $u.Description end),
                source: (if $kind == null then "unit" else "quadlet" end),
                activeState: ($u.ActiveState // ""),
                subState: ($u.SubState // ""),
                since: ($u.StateChangeTimestamp | iso),
                unitFileState: ($u.UnitFileState // ""),
                path: ($u.FragmentPath // "")
            }
            + add_if("preset"; $u.UnitFilePreset)
            + (if $kind == null then {} else {quadletFile: $u.SourcePath, quadletKind: $kind} end)
            + (if $pid != null and $pid > 0 then {mainPid: $pid} else {} end)
            + (if $mem != null and $mem < 9000000000000000000 then {memory: $mem} else {} end)
            + (if ($u.Result // "success") == "success" then {} else {result: $u.Result} end)
            + add_if("triggeredBy"; (($u.TriggeredBy // "") | split(" ") | map(select(. != "")) | join(", ")))
        ]
        | sort_by(.id)
        | {items: .}
    ' 2>/dev/null
}
