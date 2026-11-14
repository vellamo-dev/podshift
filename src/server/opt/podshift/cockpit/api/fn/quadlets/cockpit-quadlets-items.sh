#!/usr/bin/env bash
# @file: cockpit-quadlets-items.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/quadlets
# @dest-dir: /opt/podshift/cockpit/api/fn/quadlets
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the quadlets-list items from podman quadlet ls JSON and Quadlet file descriptions.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E4C91B07A2D6:-}" ]]; then
    DIR_E4C91B07A2D6="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E4C91B07A2D6
fi

# @description: Prints the first Description= value from the [Unit] section of a Quadlet file.
# @details:
#   The first matching key in the [Unit] section wins. The value is trimmed. Blank lines and
#   comments starting with # or ; are skipped. Description= in any other section is ignored.
#   An empty string is printed when the path is empty, the file is missing or unreadable, or
#   the section has no Description.
# @arg: $1 - path of the Quadlet file.
# @stdout: the trimmed Description, or an empty string.
# @exitcode: 0
cockpit-quadlets-unit-description() {
    local path
    path="${1-}"
    if [[ -z "${path}" || ! -f "${path}" || ! -r "${path}" ]]; then
        return 0
    fi
    awk '
        {
            sub(/\r$/, "")
        }
        /^[[:space:]]*\[Unit\][[:space:]]*$/ {
            in_unit = 1
            next
        }
        /^[[:space:]]*\[/ {
            in_unit = 0
            next
        }
        in_unit && /^[[:space:]]*[#;]/ { next }
        in_unit && /^[[:space:]]*Description[[:space:]]*=/ {
            sub(/^[[:space:]]*Description[[:space:]]*=/, "")
            sub(/^[[:space:]]+/, "")
            sub(/[[:space:]]+$/, "")
            print
            exit
        }
    ' < "${path}"
}

# @description: Builds a JSON object of path to Description for the paths in a quadlet ls listing.
# @details:
#   Paths are taken from the Path field of each object in the listing. Missing, unreadable or
#   description-less files map to an empty string. An invalid listing becomes {}.
# @arg: $1 - JSON array from podman quadlet ls --format json, or null, or empty for none.
# @stdout: one JSON object mapping each path to its Description string.
# @exitcode: 0
cockpit-quadlets-descriptions() {
    local raw paths path desc acc
    raw="${1-}"
    [[ -n "${raw}" ]] || raw='[]'
    paths="$(jq -c '
        if . == null then []
        elif type != "array" then []
        else
            [.[] | objects | (.Path // empty) | select(type == "string" and . != "")] | unique
        end
    ' <<< "${raw}" 2>/dev/null)" || paths='[]'
    acc='{}'
    while IFS= read -r path; do
        [[ -n "${path}" ]] || continue
        desc="$(cockpit-quadlets-unit-description "${path}")"
        acc="$(jq -nc --argjson acc "${acc}" --arg p "${path}" --arg d "${desc}" '$acc + {($p): $d}')" || acc='{}'
    done < <(jq -r '.[]' <<< "${paths}")
    printf '%s\n' "${acc}"
}

# @description: Prints {items:[...]} in the Cockpit resource card shape, sorted by title then id.
# @details:
#   Each entry from `podman quadlet ls --format json` is mapped to a Quadlet card item. The
#   Podman keys are PascalCase (Name, UnitName, Path, Status, App, Pod), as the Go ListQuadlet
#   struct has no json tags. id is the file name (Name). title is that name without a known
#   Quadlet suffix (.container, .pod, .kube, .network, .volume, .image or .build). type is
#   that suffix when it is known, and is left out otherwise. unitName, path, status, app and
#   pod are the matching fields, or empty strings when they are missing (Pod may be absent
#   on an older Podman). description is the first Description= value from the [Unit] section
#   of the file at path, trimmed, or an empty string when the file is missing, unreadable, or
#   has no Description. A null listing or an empty array becomes {items:[]}. Entries with
#   no name are skipped. Items are sorted by title, then by id, so two files that share a
#   title (for example shop.network and shop.pod) stay in a stable order.
# @arg: $1 - JSON array from podman quadlet ls --format json, or null, or empty for none.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the object was written, 1 when the argument is not the expected JSON.
cockpit-quadlets-items() {
    local raw descriptions
    raw="${1-}"
    [[ -n "${raw}" ]] || raw='[]'
    descriptions="$(cockpit-quadlets-descriptions "${raw}")"
    jq -n -c --argjson raw "${raw}" --argjson descriptions "${descriptions}" '
        def str:
            if type == "string" then .
            else "" end;
        def kinds: ["container", "pod", "kube", "network", "volume", "image", "build"];
        def typ($name):
            ($name | split(".")[-1]) as $ext
            | if ($ext != $name and ($ext as $e | kinds | index($e) != null)) then $ext else null end;
        def title($name):
            typ($name) as $t
            | if $t then $name[0:($name | length) - ($t | length) - 1] else $name end;
        def entries:
            if $raw == null then []
            elif ($raw | type) != "array" then error("not an array")
            else $raw end;
        [entries[] | objects
            | ((.Name // "") | str) as $name
            | select($name != "")
            | ((.Path // "") | str) as $path
            | {
                id: $name,
                title: title($name),
                unitName: ((.UnitName // "") | str),
                path: $path,
                status: ((.Status // "") | str),
                app: ((.App // "") | str),
                pod: ((.Pod // "") | str),
                description: ($descriptions[$path] // "")
            }
            + (typ($name) as $t | if $t then {type: $t} else {} end)
        ]
        | sort_by(.title, .id)
        | {items: .}
    ' || return 1
}
