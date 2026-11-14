#!/usr/bin/env bash
# @file: cockpit-volumes-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the volumes-list items from podman volume inspect JSON, containers, source maps and sizes.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {items:[...]} in the Cockpit resource card shape, sorted by title.
# @details:
#   id is the full volume name. title is the name, or its first 12 characters for an anonymous
#   volume (the Anonymous flag, or a name of 64 hex digits). Items have no subtitle. Rows are
#   Mountpoint (shown as ~/... under the home folder), Driver, Size (decimal units, from the size
#   map; left out when unknown), Created (UTC, ISO 8601, for the UI to format) and Used by
#   (container names sorted, each with its capitalized state, for example db (Running), or
#   Unused). Groups are details (Anonymous Yes or No, Options and Labels as key=value) and
#   systemd (for quadlet and container sources); empty rows and groups are left out. A container
#   uses a volume when its VolumeNames list, or a Mounts entry of type volume, names it. The
#   source is quadlet when the Quadlet map has the name, then container when a container using the
#   volume has the PODMAN_SYSTEMD_UNIT label, else unmanaged. For container, the systemd group
#   shows the unit of the first such container by name. status is In use when any container,
#   running or not, uses the volume, else Unused. running is true when one of them is running.
# @arg: $1 - JSON array from podman volume inspect.
# @arg: $2 - JSON array of containers: podman ps -a entries with VolumeNames or Mounts added.
# @arg: $3 - JSON object mapping a volume name to {source, unit, unit_state, file, app} from Quadlet .volume files.
# @arg: $4 - JSON object mapping a container unit name to {unit_state, file, app}.
# @arg: $5 - JSON object mapping a volume name to its size in bytes.
# @arg: $6 - the home folder for ~/... display paths, or empty.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when an argument is not the expected JSON.
cockpit-volumes-items() {
    local vols ctrs sources units sizes home
    vols="${1-}"
    ctrs="${2-}"
    sources="${3-}"
    units="${4-}"
    sizes="${5-}"
    home="${6-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    [[ -n "${sources}" ]] || sources='{}'
    [[ -n "${units}" ]] || units='{}'
    [[ -n "${sizes}" ]] || sizes='{}'
    jq -n -c --argjson vols "${vols}" --argjson ctrs "${ctrs}" --argjson sources "${sources}" \
        --argjson units "${units}" --argjson sizes "${sizes}" --arg home "${home%/}" '
        def row($id; $label; $v):
            if $v == null or $v == "" then empty
            else {id: $id, label: $label, value: ($v | tostring)} end;
        def obj: if type == "object" then . else {} end;
        def arr: if type == "array" then . elif type == "string" and . != "" then [.] else [] end;
        def kv: obj | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(", ");
        def display: if type != "string" then null
            elif $home != "" and startswith($home + "/") then "~/" + .[($home | length) + 1:]
            else . end;
        def human:
            . as $b
            | if $b < 1000 then "\($b | floor) B"
              else ([["kB", 1e3], ["MB", 1e6], ["GB", 1e9], ["TB", 1e12]] | map(select($b >= .[1])) | last) as $u
                | ($b / $u[1]) as $v
                | (if $v >= 100 then 0 elif $v >= 10 then 1 else 2 end) as $d
                | pow(10; $d) as $p
                | (($v * $p) | round) as $n
                | (($n / $p) | floor | tostring) as $int
                | (if $d == 0 then "" else (("00" + (($n % $p) | tostring))[-$d:] | sub("0+$"; "")) end) as $frac
                | (if $frac == "" then $int else $int + "." + $frac end) + " " + $u[0]
              end;
        def utc:
            if type != "string" or . == "" then null
            else (capture("^(?<d>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\\.[0-9]+)?(Z|(?<s>[-+])(?<h>[0-9]{2}):?(?<m>[0-9]{2}))?$") // null) as $c
                | if $c == null then null
                  else ((($c.d + "Z") | fromdateiso8601)
                        - (if $c.s == null then 0
                           else (($c.h | tonumber) * 3600 + ($c.m | tonumber) * 60) * (if $c.s == "-" then -1 else 1 end) end))
                       | todate
                  end
            end;
        def volnames: ((.VolumeNames | arr) + [(.Mounts | arr)[] | objects | select((.Type // "") == "volume") | .Name // empty])
            | map(tostring);
        if ($vols | type) != "array" or ($ctrs | type) != "array" or ($sources | type) != "object"
            or ($units | type) != "object" or ($sizes | type) != "object" then halt_error(1) else . end
        | {items: ($vols | map(
            . as $v
            | (($v.Name // $v.name // "") | tostring) as $name
            | ($v.Anonymous == true or ($name | test("^[0-9a-f]{64}$"))) as $anon
            | [$ctrs[] | select(any(volnames[]; . == $name))] as $uses
            | ([$uses[] | {n: ((.Names | arr)[0] // ((.Id // "") | tostring | .[0:12])), s: ((.State // "") | tostring)}]
                | unique_by(.n) | map(if .s == "" then .n else "\(.n) (\(.s[0:1] | ascii_upcase)\(.s[1:]))" end)) as $users
            | any($uses[]; ((.State // "") | tostring | ascii_downcase) == "running") as $running
            | ([$uses[] | {n: ((.Names | arr)[0] // ""), u: ((.Labels | obj).PODMAN_SYSTEMD_UNIT // "")}
                | select(.u != "")] | sort_by(.n) | first // null) as $cu
            | (($sources[$name] // null) | if type == "object" then . else null end) as $q
            | (if $q != null then "quadlet" elif $cu != null then "container" else "unmanaged" end) as $source
            | (if $source == "quadlet" then $q
               elif $source == "container" then (($units[$cu.u] // {}) | obj) + {unit: $cu.u}
               else {} end) as $s
            | {
                id: $name,
                title: (if $anon then $name[0:12] else $name end),
                status: (if ($uses | length) > 0 then "In use" else "Unused" end),
                running: $running,
                source: $source,
                rows: [
                    row("mountpoint"; "Mountpoint"; ($v.Mountpoint | display)),
                    row("driver"; "Driver"; $v.Driver),
                    row("size"; "Size"; ($sizes[$name] | if type == "number" and . >= 0 then human else null end)),
                    row("created"; "Created"; ($v.CreatedAt | utc)),
                    row("used-by"; "Used by"; (if ($users | length) > 0 then ($users | join(", ")) else "Unused" end))
                ],
                groups: ([
                    {id: "details", label: "Details", rows: [
                        row("anonymous"; "Anonymous"; (if $anon then "Yes" else "No" end)),
                        row("options"; "Options"; ($v.Options | kv)),
                        row("labels"; "Labels"; ($v.Labels | kv))
                    ]},
                    (if $source == "quadlet" or $source == "container" then
                        {id: "systemd", label: "Systemd", rows: [
                            row("unit"; "Unit name"; $s.unit),
                            row("unit_state"; "Unit state"; $s.unit_state),
                            row("file"; "File"; $s.file),
                            row("app"; "App"; $s.app)
                        ]}
                     else empty end)
                ] | map(select((.rows | length) > 0)))
              }
          ) | sort_by(.title, .id))}
    ' 2>/dev/null || return 1
}
