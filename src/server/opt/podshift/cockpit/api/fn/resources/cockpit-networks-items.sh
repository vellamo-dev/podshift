#!/usr/bin/env bash
# @file: cockpit-networks-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the networks-list items from podman network inspect JSON and a source map.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {items:[...]} in the Cockpit resource card shape, sorted by network name.
# @details:
#   Each item has id, title, subtitle, status, source, rows and groups. Rows are Driver, Subnet,
#   Gateway, Interface, IPv6, Internal and DNS; empty values are left out. Groups are systemd
#   (for quadlet and unit sources), containers (name to IP) and labels; empty groups are left out.
#   The source is builtin for the networks podman and pasta, then the source map entry, then
#   quadlet when the PODMAN_SYSTEMD_UNIT label is present, else unmanaged. status is In use when
#   any container is attached, else Unused.
#   quadlet, set only when the source map entry has source quadlet (an installed .network file),
#   is {name, app}: name is the file name and app, only for a file in a bundle folder, the app
#   name. quadlet-remove takes app when it is set, else name.
# @arg: $1 - JSON array from podman network inspect.
# @arg: $2 - JSON object mapping a network name to {source, unit, unit_state, file, app}.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when an argument is not the expected JSON.
cockpit-networks-items() {
    local nets sources
    nets="${1-}"
    sources="${2-}"
    [[ -n "${sources}" ]] || sources='{}'
    # The JSON is read from files, not arguments: Linux limits one argument to 128 KB.
    jq -n -c --slurpfile nets <(printf '%s' "${nets}") --slurpfile sources <(printf '%s' "${sources}") '
        def one: if length == 1 then .[0] else error("not one JSON value") end;
        ($nets | one) as $nets | ($sources | one) as $sources |
        def row($id; $label; $v):
            if $v == null or $v == "" then empty
            else {id: $id, label: $label, value: ($v | tostring)} end;
        def owner: if type != "object" then null
            else (((.file // "") | if type == "string" then . else "" end | split("/") | last) // "") as $f
                | ((.app // "") | if type == "string" then . else "" end) as $a
                | if $f == "" then null else {name: $f} + (if $a == "" then {} else {app: $a} end) end end;
        def flag($b; $yes; $no):
            if $b == true then $yes elif $b == false then $no else null end;
        if ($nets | type) != "array" or ($sources | type) != "object" then halt_error(1) else . end
        | {items: ($nets | map(
            . as $n
            | ($n.name // "") as $name
            | (($sources[$name] // {}) | if type == "object" then . else {} end) as $s
            | (($n.labels // {}) | if type == "object" then . else {} end) as $labels
            | ([($n.containers // {}) | to_entries[]
                | {name: (.value.name // (.key[0:12])),
                   ip: ([(.value.interfaces // {}) | to_entries[] | (.value.subnets // [])[] | .ipnet // empty] | first // null)}]
               | sort_by(.name)) as $ctrs
            | (if $name == "podman" or $name == "pasta" then "builtin"
               elif ($s.source // "") != "" then $s.source
               elif ($labels | has("PODMAN_SYSTEMD_UNIT")) then "quadlet"
               else "unmanaged" end) as $source
            | (if ($s.source // "") == "quadlet" then ($s | owner) else null end) as $owner
            | (if ($s.unit // "") != "" then $s.unit
               elif $source == "quadlet" then ($labels.PODMAN_SYSTEMD_UNIT // null)
               else null end) as $unit
            | {
                id: $name,
                title: $name,
                subtitle: (($n.id // "") | tostring | .[0:12]),
                status: (if ($ctrs | length) > 0 then "In use" else "Unused" end),
                source: $source,
                rows: [
                    row("driver"; "Driver"; $n.driver),
                    row("subnet"; "Subnet"; ([($n.subnets // [])[] | .subnet // empty] | join(", "))),
                    row("gateway"; "Gateway"; ([($n.subnets // [])[] | .gateway // empty] | join(", "))),
                    row("interface"; "Interface"; $n.network_interface),
                    row("ipv6"; "IPv6"; flag($n.ipv6_enabled; "Enabled"; "Disabled")),
                    row("internal"; "Internal"; flag($n.internal; "Yes"; "No")),
                    row("dns"; "DNS"; flag($n.dns_enabled; "Enabled"; "Disabled"))
                ],
                groups: ([
                    (if $source == "quadlet" or $source == "unit" then
                        {id: "systemd", label: "Systemd", rows: [
                            row("unit"; "Unit name"; $unit),
                            row("unit_state"; "Unit state"; $s.unit_state),
                            row("file"; "File"; $s.file),
                            row("app"; "App"; $s.app)
                        ]}
                     else empty end),
                    {id: "containers", label: "Containers", rows: [
                        $ctrs[] | row(.name; .name; (if .ip == null then "No IP" else (.ip | split("/")[0]) end))
                    ]},
                    {id: "labels", label: "Labels", rows: [
                        $labels | to_entries | sort_by(.key)[] | row(.key; .key; .value)
                    ]}
                ] | map(select((.rows | length) > 0)))
              }
            + (if $owner == null then {} else {quadlet: $owner} end)
          ) | sort_by(.id))}
    '
}
