#!/usr/bin/env bats
# Unit test for cockpit-images-items (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-images-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-images-items.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-images"
    INSPECT="$(cat "${FIX}/inspect.json")"
    CONTAINERS="$(cat "${FIX}/containers.json")"
    SOURCES="$(cat "${FIX}/sources.json")"
    UNITS="$(cat "${FIX}/units.json")"
}

@test "items are sorted by title and have the card fields" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].title] == ["<none>","alpine","busybox","nginx","postgres"]
        and all(.items[]; (keys | sort) == ["fullId","groups","id","rows","running","source","status","subtitle","title"])
        and all(.items[]; .id == .subtitle and (.id | length) == 12 and (.fullId | length) == 64 and (. as $i | $i.fullId | startswith($i.id)))
        and (.items[] | select(.title == "alpine") | .id) == "abbc135a7d39"
        and (.items[] | select(.title == "alpine") | .fullId) == "abbc135a7d39c0e8a2fd3b9b5d0a3c1c8f0e8d2b4a6c9e1f3a5b7d9c1e3f5a7b"
    '
}

@test "rows: URL, tags, registry, size, created and used by" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.title == "postgres") | .rows) == [
            {"id":"url","label":"URL","value":"docker.io/library/postgres:16"},
            {"id":"tags","label":"Tags","value":"16, latest"},
            {"id":"registry","label":"Registry","value":"docker.io"},
            {"id":"size","label":"Size","value":"432 MB"},
            {"id":"created","label":"Created","value":"2026-11-01T10:00:00Z"},
            {"id":"used-by","label":"Used by","value":"db (Running), db-backup (Exited)"}
        ]
        and ([.items[] | {(.title): (.rows[] | select(.id == "size") | .value)}] | add)
            == {"<none>":"512 B","alpine":"8.95 MB","busybox":"4.43 MB","nginx":"61.9 MB","postgres":"432 MB"}
        and (.items[] | select(.title == "alpine") | .rows[] | select(.id == "created") | .value) == "2026-11-05T10:12:00Z"
        and (.items[] | select(.title == "alpine") | .rows[] | select(.id == "used-by") | .value) == "Unused"
    '
}

@test "a dangling image is titled <none> and has no URL, tags or registry" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.title == "<none>") | [.rows[].id]) == ["size","created","used-by"]
    '
    run cockpit-images-items '[{"Id":"sha256:ffffeeeeddddccccbbbb","RepoTags":["<none>:<none>"]}]' '[]' '{}' '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].title == "<none>" and .items[0].id == "ffffeeeedddd" and .items[0].fullId == "ffffeeeeddddccccbbbb"'
}

@test "source: quadlet wins, then a container unit, else unmanaged" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): .source}] | add) == {
            "<none>": "unmanaged",
            "alpine": "unmanaged",
            "busybox": "quadlet",
            "nginx": "container",
            "postgres": "unmanaged"
        }
    '
}

@test "status is In use with any container, running or not" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): .status}] | add) == {
            "<none>": "Unused",
            "alpine": "Unused",
            "busybox": "In use",
            "nginx": "In use",
            "postgres": "In use"
        }
    '
}

@test "running is true when a using container runs, states are capitalized" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): .running}] | add) == {
            "<none>": false,
            "alpine": false,
            "busybox": true,
            "nginx": true,
            "postgres": true
        }
    '
    run cockpit-images-items '[{"Id":"abcdefabcdef0000","RepoTags":["docker.io/library/alpine:latest"]}]' \
        '[{"Names":["b"],"ImageID":"abcdefabcdef0000","State":"paused"},{"Names":["a"],"ImageID":"abcdefabcdef0000","State":"created"}]' '{}' '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .items[0].running == false and .items[0].status == "In use"
        and (.items[0].rows[] | select(.id == "used-by") | .value) == "a (Created), b (Paused)"
    '
}

@test "groups: details and systemd, empty rows and groups left out" {
    run cockpit-images-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.title == "nginx") | .groups) == [
            {"id":"details","label":"Details","rows":[
                {"id":"command","label":"Command","value":"/docker-entrypoint.sh nginx -g \u0027daemon off;\u0027"},
                {"id":"architecture","label":"Architecture","value":"amd64"},
                {"id":"os","label":"OS","value":"linux"},
                {"id":"digest","label":"Digest","value":"sha256:c8e4d91a07b2"},
                {"id":"labels","label":"Labels","value":"maintainer=NGINX Docker Maintainers"}
            ]},
            {"id":"systemd","label":"Systemd","rows":[
                {"id":"unit","label":"Unit name","value":"web.service"},
                {"id":"unit_state","label":"Unit state","value":"active"},
                {"id":"file","label":"File","value":"~/.config/containers/systemd/web.container"}
            ]}
        ]
        and ((.items[] | select(.title == "busybox") | .groups[1].rows) == [
            {"id":"unit","label":"Unit name","value":"busybox-image.service"},
            {"id":"unit_state","label":"Unit state","value":"active"},
            {"id":"file","label":"File","value":"~/.config/containers/systemd/shop.qdl-bundle/busybox.image"},
            {"id":"app","label":"App","value":"shop"}
        ])
        and ([.items[] | select(.title == "alpine") | .groups[].id] == ["details"])
        and ([.items[] | select(.title == "alpine") | .groups[0].rows[].id] == ["command","architecture","os","digest"])
    '
}

@test "empty input gives no items" {
    run cockpit-images-items '[]' '' '' ''
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
}

@test "arguments that are not the expected JSON return 1" {
    run cockpit-images-items 'not json' '[]' '{}' '{}'
    [ "${status}" -eq 1 ]
    run cockpit-images-items '{}' '[]' '{}' '{}'
    [ "${status}" -eq 1 ]
    run cockpit-images-items '[]' '{}' '{}' '{}'
    [ "${status}" -eq 1 ]
}
