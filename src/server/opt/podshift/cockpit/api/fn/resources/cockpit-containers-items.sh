#!/usr/bin/env bash
# @file: cockpit-containers-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the containers-list items from podman ps, container inspect, unit maps and stats JSON.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {items:[...]} in the Cockpit resource card shape, sorted by name.
# @details:
#   One item per podman ps -a entry. id is the full container ID, title the first name and
#   subtitle the first 12 characters of the ID. status is the capitalized state (Running, Paused,
#   Exited, Created, ...; the podman ps state wins, and stopped, which podman inspect reports for
#   an exited container after cleanup, is shown as Exited). running is true for a running
#   container. Rows are Image, Command,
#   State (the podman ps status text, for example Up 3 days), Health (only with a health check),
#   Ports (host -> container/protocol, shown with an arrow) and Created (UTC, ISO 8601). Groups are
#   details (Networks, Volumes as name or path -> destination, Auto-update, Restart policy, CPU and
#   Memory) and systemd (quadlet and unit sources only); empty rows and groups are left out. CPU
#   and Memory come from the stats array and are shown only for running containers. The unit is
#   the PODMAN_SYSTEMD_UNIT label. The source is unmanaged when there is no unit or systemd does
#   not know it (LoadState not-found), quadlet when the Quadlet map has the unit or the unit file
#   is a .container file, else unit. autoUpdate is registry or local from the
#   io.containers.autoupdate label (image counts as registry) and is missing when off.
#   autoUpdateActive, set only with autoUpdate, is true when the unit is set and active.
# @arg: $1 - JSON array from podman ps -a --format json.
# @arg: $2 - JSON array from podman container inspect.
# @arg: $3 - JSON object mapping a unit name to {file, app} from Quadlet .container files.
# @arg: $4 - JSON object mapping a container unit name to {unit_state, load_state, file, app}.
# @arg: $5 - JSON array from podman stats --no-stream --format json, or [].
# @arg: $6 - the home folder for ~/... display paths, or empty.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when an argument is not the expected JSON.
cockpit-containers-items() {
    local ps inspect quadlets units stats home
    ps="${1-}"
    inspect="${2-}"
    quadlets="${3-}"
    units="${4-}"
    stats="${5-}"
    home="${6-}"
    [[ -n "${inspect}" ]] || inspect='[]'
    [[ -n "${quadlets}" ]] || quadlets='{}'
    [[ -n "${units}" ]] || units='{}'
    [[ -n "${stats}" ]] || stats='[]'
    jq -n -c --argjson ps "${ps}" --argjson ins "${inspect}" --argjson quadlets "${quadlets}" \
        --argjson units "${units}" --argjson stats "${stats}" --arg home "${home%/}" '
        def row($id; $label; $v):
            if $v == null or $v == "" then empty
            else {id: $id, label: $label, value: ($v | tostring)} end;
        def obj: if type == "object" then . else {} end;
        def arr: if type == "array" then . elif type == "string" and . != "" then [.] else [] end;
        def str: if . == null then "" else tostring end;
        def cap: if . == "" then . else (.[0:1] | ascii_upcase) + .[1:] end;
        def shq: if test("\\s") then "\u0027" + . + "\u0027" else . end;
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
        def bytes:
            if type == "number" then .
            elif type == "string" then
                ((split("/")[0] | gsub("^\\s+|\\s+$"; "")) | capture("^(?<n>[0-9]+(\\.[0-9]+)?)\\s*(?<u>[kKMGT]?)(?<i>i?)B$") // null)
                | if . == null then null
                  else (if .i == "i" then 1024 else 1000 end) as $base
                    | ({"": 0, "K": 1, "M": 2, "G": 3, "T": 4}[.u | ascii_upcase]) as $e
                    | (.n | tonumber) * pow($base; $e)
                  end
            else null end;
        def cpu:
            if type == "number" then ((. * 100 | round) / 100 | tostring) + "%"
            elif type == "string" and . != "" then gsub("\\s"; "")
            else null end;
        def port:
            (.host_ip // .hostIP // "" | str | if . == "" then "0.0.0.0" else . end) as $ip
            | ((.range // 1) | if type == "number" and . > 1 then . else 1 end) as $r
            | (.host_port // .hostPort) as $hp
            | (.container_port // .containerPort) as $cp
            | if $hp == null or $cp == null then empty
              else "\($ip):\(if $r > 1 then "\($hp)-\($hp + $r - 1)" else "\($hp)" end) → "
                + "\(if $r > 1 then "\($cp)-\($cp + $r - 1)" else "\($cp)" end)/\(.protocol // "tcp")" end;
        def mount:
            if (.Type // "") == "volume" and (.Name // "") != "" then "\(.Name) → \(.Destination // "")"
            elif (.Type // "") == "bind" and (.Source // "") != "" then "\(.Source | display) → \(.Destination // "")"
            else empty end;
        if ($ps | type) != "array" or ($ins | type) != "array" or ($quadlets | type) != "object"
            or ($units | type) != "object" or ($stats | type) != "array" then halt_error(1) else . end
        | ([$ins[] | objects | {key: ((.Id // .ID // "") | str), value: .}] | from_entries) as $byid
        | {items: ($ps | map(
            . as $p
            | (($p.Id // $p.ID // "") | str) as $id
            | (($byid[$id] // {}) | obj) as $i
            | ($i.State | obj) as $st
            | (($p.State // $st.Status // "") | str | ascii_downcase | if . == "stopped" then "exited" else . end) as $state
            | ((($p.Names | arr)[0] // ($i.Name // "" | str | ltrimstr("/")) | str)
                | if . == "" then $id[0:12] else . end) as $name
            | (($p.Labels | obj) + (($i.Config | obj).Labels | obj)) as $labels
            | (($labels.PODMAN_SYSTEMD_UNIT // "") | str) as $unit
            | (if $unit == "" then {} else (($units[$unit] // {}) | obj) end) as $u
            | (if $unit == "" then null else ($quadlets[$unit] // null) | (if type == "object" then . else null end) end) as $q
            | (if $unit == "" or (($u.load_state // "") == "not-found" and $q == null) then "unmanaged"
               elif $q != null or (($u.file // "") | str | endswith(".container")) then "quadlet"
               else "unit" end) as $source
            | (($labels["io.containers.autoupdate"] // "") | str | ascii_downcase
                | if . == "registry" or . == "image" then "registry" elif . == "local" then "local" else null end) as $au
            | ($state == "running") as $running
            | (if $running then (first($stats[] | objects
                    | select(((.id // .ID // .ContainerID // "") | str) as $s | $s != "" and ($id | startswith($s)))) // null)
               else null end) as $stat
            | ((($st.Health // $st.Healthcheck // {}) | obj).Status // "" | str) as $health
            | ([($p.Networks | arr)[] | str | select(. != "")] | sort) as $pnets
            | (if ($pnets | length) > 0 then $pnets
               else ((($i.NetworkSettings | obj).Networks | obj) | keys) end) as $nets
            | {
                id: $id,
                title: $name,
                subtitle: $id[0:12],
                status: ($state | cap),
                running: $running,
                source: $source,
                rows: [
                    row("image"; "Image"; ($p.Image // $i.ImageName // ($i.Config | obj).Image)),
                    row("command"; "Command"; ((if ($p.Command | arr | length) > 0 then ($p.Command | arr) else (($i.Config | obj).Cmd | arr) end)
                        | map(str | shq) | join(" "))),
                    row("state"; "State"; (($p.Status // "") | str | if . == "" then ($state | cap) else . end)),
                    row("health"; "Health"; ($health | cap)),
                    row("ports"; "Ports"; ([($p.Ports | arr)[] | objects | port] | join(", "))),
                    row("created"; "Created"; (($i.Created | utc)
                        // ($p.Created | if type == "number" and . > 0 then (floor | todate) else null end)))
                ],
                groups: ([
                    {id: "details", label: "Details", rows: [
                        row("networks"; "Networks"; (if ($nets | length) > 0 then ($nets | join(", "))
                            else (($i.HostConfig | obj).NetworkMode // null) end)),
                        row("volumes"; "Volumes"; ([($i.Mounts | arr)[] | objects | mount] | join(", "))),
                        row("auto-update"; "Auto-update"; (if $au == null then "Off" else ($au | cap) end)),
                        row("restart"; "Restart policy"; ((((($i.HostConfig | obj).RestartPolicy | obj).Name) // "") | str
                            | if . == "" then "no" else . end)),
                        row("cpu"; "CPU"; (if $stat == null then null else (($stat.cpu_percent // $stat.CPU) | cpu) end)),
                        row("memory"; "Memory"; (if $stat == null then null
                            else (($stat.mem_usage // $stat.MemUsage) | bytes | if type == "number" and . >= 0 then human else null end) end))
                    ]},
                    (if $source == "quadlet" or $source == "unit" then
                        {id: "systemd", label: "Systemd", rows: [
                            row("unit"; "Unit name"; $unit),
                            row("unit_state"; "Unit state"; $u.unit_state),
                            row("file"; "File"; ($q.file // $u.file)),
                            row("app"; "App"; ($q.app // $u.app))
                        ]}
                     else empty end)
                ] | map(select((.rows | length) > 0)))
              }
            + (if $au == null then {}
               else {autoUpdate: $au, autoUpdateActive: ($unit != "" and ($u.unit_state // "") == "active")} end)
          ) | sort_by(.title, .id))}
    ' 2>/dev/null || return 1
}
