#!/usr/bin/env bash
# @file: cockpit-images-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the images-list items from podman image inspect JSON, containers and source maps.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {items:[...]} in the Cockpit resource card shape, sorted by short name.
# @details:
#   One item per image ID; several tags of one image share one item. id and subtitle are the first
#   12 characters of the image ID, shown and copied in the UI. fullId is the full image ID without
#   sha256:, the ref the UI passes to inspect. title is the short name of the first tag (the last path part
#   without the tag, for example alpine), or <none> for a dangling image. Rows are URL (the first
#   full tag), Tags (every tag, joined with ", "), Registry, Size (decimal units, like podman),
#   Created (UTC, ISO 8601, for the UI to format) and Used by (container names sorted, each with its
#   capitalized state, for example db (Running), or Unused). Groups
#   are details (Command, Architecture, OS, Digest shortened to 12 hex digits, Labels) and systemd
#   (for quadlet and container sources); empty rows and groups are left out. The source is quadlet
#   when a tag matches a key of the Quadlet map, either fully or after a slash, then container when
#   a container using the image has the PODMAN_SYSTEMD_UNIT label, else unmanaged. For container,
#   the systemd group shows the unit of the first such container by name. status is In use when any
#   container, running or not, uses the image, else Unused. running is true when at least one
#   of those containers is running.
# @arg: $1 - JSON array from podman image inspect.
# @arg: $2 - JSON array from podman ps -a --format json.
# @arg: $3 - JSON object mapping an image reference to {source, unit, unit_state, file, app} from Quadlet .image files.
# @arg: $4 - JSON object mapping a container unit name to {unit_state, file, app}.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when an argument is not the expected JSON.
cockpit-images-items() {
    local images ctrs sources units
    images="${1-}"
    ctrs="${2-}"
    sources="${3-}"
    units="${4-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    [[ -n "${sources}" ]] || sources='{}'
    [[ -n "${units}" ]] || units='{}'
    jq -n -c --argjson images "${images}" --argjson ctrs "${ctrs}" --argjson sources "${sources}" \
        --argjson units "${units}" '
        def row($id; $label; $v):
            if $v == null or $v == "" then empty
            else {id: $id, label: $label, value: ($v | tostring)} end;
        def obj: if type == "object" then . else {} end;
        def arr: if type == "array" then . elif type == "string" and . != "" then [.] else [] end;
        def uniq: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
        def bare: tostring | sub("^sha256:"; "");
        def repo: sub("@.*$"; "") | sub(":[^/:]*$"; "");
        def tag: sub("@.*$"; "") | (capture(":(?<t>[^/:]*)$") // {t: null}).t;
        def registry: repo | split("/") | if length > 1 then .[0] else null end;
        def shq: if test("\\s") then "\u0027" + . + "\u0027" else . end;
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
        if ($images | type) != "array" or ($ctrs | type) != "array"
            or ($sources | type) != "object" or ($units | type) != "object" then halt_error(1) else . end
        | ($sources | keys) as $refs
        | {items: ($images | map(
            . as $i
            | (($i.Id // $i.ID // "") | bare) as $fullid
            | ($fullid[0:12]) as $sid
            | ($i.Config | obj) as $config
            | [($i.RepoTags | arr)[] | select(type == "string" and . != "" and (startswith("<none>") | not))] as $names
            | ($names[0] // null) as $first
            | [$ctrs[] | select(((.ImageID // "") | bare) as $c | $c != "" and ($fullid | startswith($c)))] as $uses
            | ([$uses[] | {n: ((.Names | arr)[0] // ((.Id // "") | tostring | .[0:12])), s: ((.State // "") | tostring)}]
                | unique_by(.n) | map(if .s == "" then .n else "\(.n) (\(.s[0:1] | ascii_upcase)\(.s[1:]))" end)) as $users
            | any($uses[]; ((.State // "") | tostring | ascii_downcase) == "running") as $running
            | ([$uses[] | {n: ((.Names | arr)[0] // ""), u: ((.Labels | obj).PODMAN_SYSTEMD_UNIT // "")}
                | select(.u != "")] | sort_by(.n) | first // null) as $cu
            | (first($refs[] as $r | $names[] | select(. == $r or endswith("/" + $r)) | ($sources[$r] | obj)) // null) as $q
            | (if $q != null then "quadlet" elif $cu != null then "container" else "unmanaged" end) as $source
            | (if $source == "quadlet" then $q
               elif $source == "container" then (($units[$cu.u] // {}) | obj) + {unit: $cu.u}
               else {} end) as $s
            | {
                id: $sid,
                fullId: $fullid,
                title: (if $first == null then "<none>" else ($first | repo | split("/") | last) end),
                subtitle: $sid,
                status: (if ($uses | length) > 0 then "In use" else "Unused" end),
                running: $running,
                source: $source,
                rows: [
                    row("url"; "URL"; $first),
                    row("tags"; "Tags"; ([$names[] | tag | select(. != null)] | uniq | join(", "))),
                    row("registry"; "Registry"; (if $first == null then null else ($first | registry) end)),
                    row("size"; "Size"; (($i.Size // $i.VirtualSize) | if type == "number" then human else null end)),
                    row("created"; "Created"; ($i.Created | utc)),
                    row("used-by"; "Used by"; (if ($users | length) > 0 then ($users | join(", ")) else "Unused" end))
                ],
                groups: ([
                    {id: "details", label: "Details", rows: [
                        row("command"; "Command"; (($config.Entrypoint | arr) + ($config.Cmd | arr) | map(tostring | shq) | join(" "))),
                        row("architecture"; "Architecture"; $i.Architecture),
                        row("os"; "OS"; $i.Os),
                        row("digest"; "Digest"; ($i.Digest | if type == "string" and . != ""
                            then (if startswith("sha256:") then .[0:19] else .[0:12] end) else null end)),
                        row("labels"; "Labels"; ((($i.Labels // $config.Labels) | obj) | to_entries | sort_by(.key)
                            | map("\(.key)=\(.value)") | join(", ")))
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
