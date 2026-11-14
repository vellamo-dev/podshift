#!/usr/bin/env bats
# Unit test for cockpit-volumes-items (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-volumes-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-volumes-items.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-volumes"
    INSPECT="$(cat "${FIX}/inspect.json")"
    CONTAINERS="$(cat "${FIX}/containers.json")"
    SOURCES="$(cat "${FIX}/sources.json")"
    UNITS="$(cat "${FIX}/units.json")"
    SIZES="$(cat "${FIX}/sizes.json")"
    ANON="3f9a1c7e5b2d4086a1e9c3b7d5f2048e6a9c1b3d5f7e9a2c4b6d8f0e1a3c5b7d"
}

@test "items are sorted by title and have the card fields, without a subtitle" {
    run cockpit-volumes-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}" "${SIZES}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].title] == ["3f9a1c7e5b2d","backups","cache","pgdata","web-data"]
        and all(.items[]; (keys | sort) == ["groups","id","rows","running","source","status","title"])
    '
}

@test "rows: mountpoint under home, driver, size, created and used by" {
    run cockpit-volumes-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}" "${SIZES}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "pgdata") | .rows) == [
            {"id":"mountpoint","label":"Mountpoint","value":"~/.local/share/containers/storage/volumes/pgdata/_data"},
            {"id":"driver","label":"Driver","value":"local"},
            {"id":"size","label":"Size","value":"412 MB"},
            {"id":"created","label":"Created","value":"2026-10-28T09:15:00Z"},
            {"id":"used-by","label":"Used by","value":"db (Running)"}
        ]
        and ([.items[] | {(.title): (.rows[] | select(.id == "size") | .value)}] | add)
            == {"3f9a1c7e5b2d":"4.1 kB","backups":"1.82 GB","cache":"96.1 MB","pgdata":"412 MB","web-data":"23.4 MB"}
        and (.items[] | select(.id == "cache") | .rows[] | select(.id == "used-by") | .value) == "cache-warmup (Exited)"
        and (.items[] | select(.id == "backups") | .rows[] | select(.id == "used-by") | .value) == "Unused"
    '
}

@test "a missing size leaves the row out, and paths outside home stay full" {
    run cockpit-volumes-items '[{"Name":"x","Driver":"local","Mountpoint":"/var/lib/x/_data"}]' '[]' '{}' '{}' '{}' /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[0].rows[].id] == ["mountpoint","driver","used-by"]
        and .items[0].rows[0].value == "/var/lib/x/_data"
    '
}

@test "an anonymous volume is titled with 12 characters and keeps its full name as id" {
    run cockpit-volumes-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}" "${SIZES}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e --arg anon "${ANON}" '
        (.items[] | select(.id == $anon) | .title) == "3f9a1c7e5b2d"
        and (.items[] | select(.id == $anon) | .groups[0].rows) == [{"id":"anonymous","label":"Anonymous","value":"Yes"}]
        and (.items[] | select(.id == "backups") | .groups[0].rows[0].value) == "No"
    '
    run cockpit-volumes-items '[{"Name":"short","Anonymous":true}]' '[]' '{}' '{}' '{}' ''
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].groups[0].rows[0].value == "Yes"'
}

@test "source: quadlet wins, then a container unit, else unmanaged" {
    run cockpit-volumes-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}" "${SIZES}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): .source}] | add) == {
            "3f9a1c7e5b2d": "unmanaged",
            "backups": "unmanaged",
            "cache": "unmanaged",
            "pgdata": "quadlet",
            "web-data": "container"
        }
    '
}

@test "status and running follow the containers that mount the volume" {
    run cockpit-volumes-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}" "${SIZES}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): [.status, .running]}] | add) == {
            "3f9a1c7e5b2d": ["In use", true],
            "backups": ["Unused", false],
            "cache": ["In use", false],
            "pgdata": ["In use", true],
            "web-data": ["In use", true]
        }
    '
}

@test "groups: details and systemd, empty rows and groups left out" {
    run cockpit-volumes-items "${INSPECT}" "${CONTAINERS}" "${SOURCES}" "${UNITS}" "${SIZES}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "pgdata") | .groups) == [
            {"id":"details","label":"Details","rows":[
                {"id":"anonymous","label":"Anonymous","value":"No"},
                {"id":"labels","label":"Labels","value":"podshift.app=shop"}
            ]},
            {"id":"systemd","label":"Systemd","rows":[
                {"id":"unit","label":"Unit name","value":"pgdata-volume.service"},
                {"id":"unit_state","label":"Unit state","value":"active"},
                {"id":"file","label":"File","value":"~/.config/containers/systemd/shop.qdl-bundle/pgdata.volume"},
                {"id":"app","label":"App","value":"shop"}
            ]}
        ]
        and ((.items[] | select(.id == "web-data") | .groups[1].rows) == [
            {"id":"unit","label":"Unit name","value":"web.service"},
            {"id":"unit_state","label":"Unit state","value":"active"},
            {"id":"file","label":"File","value":"~/.config/containers/systemd/web.container"}
        ])
        and ((.items[] | select(.id == "cache") | .groups[0].rows[1]) == {"id":"options","label":"Options","value":"device=tmpfs, o=size=256m, type=tmpfs"})
        and ([.items[] | select(.id == "backups") | .groups[].id] == ["details"])
    '
}

@test "empty input gives no items" {
    run cockpit-volumes-items '[]' '' '' '' '' ''
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
}

@test "arguments that are not the expected JSON return 1" {
    run cockpit-volumes-items 'not json' '[]' '{}' '{}' '{}' ''
    [ "${status}" -eq 1 ]
    run cockpit-volumes-items '{}' '[]' '{}' '{}' '{}' ''
    [ "${status}" -eq 1 ]
    run cockpit-volumes-items '[]' '[]' '{}' '{}' '[]' ''
    [ "${status}" -eq 1 ]
}
