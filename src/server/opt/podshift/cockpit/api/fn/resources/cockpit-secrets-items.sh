#!/usr/bin/env bash
# @file: cockpit-secrets-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the secrets-list items from podman secret inspect JSON and podman container inspect JSON.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {items:[...]} in the Cockpit resource card shape, sorted by title, without secret values.
# @details:
#   Only the ID, name, driver name and times of a secret are read, so SecretData or driver options
#   never reach the output. id is the full secret ID, title and name the secret name, subtitle the
#   first 12 characters of the ID. created and updated are UTC ISO 8601 (updated falls back to
#   created), or empty when unknown. usedBy lists every container that references the secret, as
#   {container, containerId, state, type, target}: a --secret option in Config.CreateCommand gives
#   type file (target /run/secrets/<target or name>, or the absolute target) or type env (target
#   is the variable name, the target option or the secret name). A Config.Secrets entry that no
#   --secret option covers is added as type file at /run/secrets/<name>. A container matches by
#   secret name or ID. inUse is true when usedBy is not empty, for stopped containers too. status
#   is In use or Unused, running is true when a container that uses it is running. Rows are Driver,
#   Created, Updated and Used by (for example db (env DB_PASSWORD), web (file at /run/secrets/x),
#   or Unused); empty rows are left out.
# @arg: $1 - JSON array from podman secret inspect (without --showsecret).
# @arg: $2 - JSON array from podman container inspect, or empty for none.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when an argument is not the expected JSON.
cockpit-secrets-items() {
    local secrets ctrs
    secrets="${1-}"
    ctrs="${2-}"
    [[ -n "${ctrs}" ]] || ctrs='[]'
    jq -n -c --argjson secrets "${secrets}" --argjson ctrs "${ctrs}" '
        def row($id; $label; $v):
            if $v == null or $v == "" then empty
            else {id: $id, label: $label, value: ($v | tostring)} end;
        def obj: if type == "object" then . else {} end;
        def arr: if type == "array" then . else [] end;
        def str: if type == "string" then . elif type == "number" then tostring else "" end;
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
        def secretopts:
            (.Config | obj | .CreateCommand | arr | map(str)) as $c
            | [range(0; $c | length) as $i
                | if $c[$i] == "--secret" then ($c[$i + 1] // "")
                  elif ($c[$i] | startswith("--secret=")) then $c[$i][9:]
                  else empty end
                | select(. != "")];
        def parse:
            split(",") as $p
            | ([$p[1:][] | select(contains("=")) | {key: (split("=")[0]), value: .[(index("=") + 1):]}] | from_entries) as $o
            | (if ($o.type // "mount") == "env" then "env" else "file" end) as $t
            | (($o.target // "") | if . == "" then $p[0] else . end) as $target
            | {ref: $p[0], type: $t,
               target: (if $t == "env" then $target elif ($target | startswith("/")) then $target else "/run/secrets/" + $target end)};
        def refs:
            [secretopts[] | parse] as $opts
            | $opts + [(.Config | obj | .Secrets | arr)[] | objects
                | {ref: (.Name | str), id: (.ID | str), type: "file", target: ("/run/secrets/" + (.Name | str))}
                | select(.ref != "") | . as $s
                | select(all($opts[]; .type != "file" or (.ref != $s.ref and .ref != $s.id)))];
        def uses($name; $id):
            [$ctrs[] | objects
                | ((.Name // ((.Names | arr)[0]) // "") | str | ltrimstr("/")) as $cname
                | ((.Id // .ID // "") | str) as $cid
                | ((.State | if type == "object" then .Status else . end) | str | ascii_downcase) as $state
                | refs[]
                | select(.ref == $name or (.ref != "" and .ref == $id) or ((.id // "") != "" and .id == $id))
                | {container: (if $cname == "" then $cid[0:12] else $cname end), containerId: $cid, state: $state,
                   type: .type, target: .target}]
            | unique_by([.container, .containerId, .type, .target]);
        def usertext:
            "\(.container) (\(if .type == "env" then "env " else "file at " end)\(.target))";
        if ($secrets | type) != "array" or ($ctrs | type) != "array" then halt_error(1) else . end
        | {items: ([$secrets[] | objects
            | (.Spec | obj) as $spec
            | ((.ID // .Id // "") | str) as $id
            | (($spec.Name // .Name // "") | str) as $name
            | (($spec.Driver // .Driver // "") | if type == "object" then (.Name | str) else str end) as $driver
            | ((.CreatedAt // "") | utc // "") as $created
            | ((.UpdatedAt // "") | utc // $created) as $updated
            | uses($name; $id) as $users
            | {
                id: $id,
                title: (if $name == "" then $id[0:12] else $name end),
                subtitle: $id[0:12],
                name: $name,
                driver: $driver,
                created: $created,
                updated: $updated,
                status: (if ($users | length) > 0 then "In use" else "Unused" end),
                inUse: (($users | length) > 0),
                running: any($users[]; .state == "running"),
                usedBy: $users,
                rows: [
                    row("driver"; "Driver"; $driver),
                    row("created"; "Created"; $created),
                    row("updated"; "Updated"; $updated),
                    row("used-by"; "Used by"; (if ($users | length) > 0 then ($users | map(usertext) | join(", ")) else "Unused" end))
                ]
              }
          ] | sort_by(.title, .id))}
    ' 2>/dev/null || return 1
}
