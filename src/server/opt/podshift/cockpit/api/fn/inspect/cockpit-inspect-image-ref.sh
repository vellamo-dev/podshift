#!/usr/bin/env bash
# @file: cockpit-inspect-image-ref.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/inspect
# @dest-dir: /opt/podshift/cockpit/api/fn/inspect
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Resolves an image ID prefix to the full image ID and first tag, from podman image ls JSON.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the full ID and the first tag of the one image whose ID starts with the ref.
# @details:
#   Used when podman image inspect does not find a short image ID. The ref may start with
#   sha256: and must then be 4 to 64 hex digits (any case). IDs are compared without sha256:, in
#   lower case. Several list entries with the same ID are one image. No match, or a prefix shared
#   by more than one image, prints nothing. The tag is the first of Names (or RepoTags) that is
#   not <none> and is a valid inspect ref (letters, digits and ._:/@-, no leading dash), else empty.
# @arg: $1 - JSON array from podman image ls --format json.
# @arg: $2 - ref as requested, for example abbc135a7d39.
# @stdout: one line, the full ID and the tag separated by a tab, for example "abbc...<TAB>docker.io/library/alpine:latest".
# @exitcode: 0 when one image matched, 1 when none or several matched, or an argument is not valid.
cockpit-inspect-image-ref() {
    local images ref
    images="${1-}"
    ref="${2-}"
    jq -n -r -e --argjson images "${images}" --arg ref "${ref}" '
        def bare: tostring | ascii_downcase | sub("\\Asha256:"; "");
        def tags: if type == "array" then [.[] | select(type == "string"
            and test("\\A[A-Za-z0-9._:/@][A-Za-z0-9._:/@-]{0,255}\\z") and (startswith("<none>") | not))] else [] end;
        ($ref | bare) as $p
        | if ($images | type) != "array" or ($p | test("\\A[0-9a-f]{4,64}\\z") | not) then empty
          else [$images[] | select(type == "object")
                | {id: ((.Id // .ID // "") | bare), tags: ((.Names // .RepoTags) | tags)}
                | select((.id | test("\\A[0-9a-f]{1,64}\\z")) and (.id | startswith($p)))]
            | group_by(.id)
            | if length == 1 then .[0][0].id + "\t" + ([.[0][].tags[]][0] // "") else empty end
          end
    ' 2>/dev/null || return 1
}
