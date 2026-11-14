#!/usr/bin/env bats
# Unit test for cockpit-containers-items (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-containers-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-containers-items.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-containers"
    PS="$(cat "${FIX}/ps.json")"
    INSPECT="$(cat "${FIX}/inspect.json")"
    QUADLETS="$(cat "${FIX}/quadlets.json")"
    UNITS="$(cat "${FIX}/units.json")"
    STATS="$(cat "${FIX}/stats.json")"
}

@test "items are sorted by name and have the card fields" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].title] == ["db","db-backup","ghost","old-build","scratch","worker"]
        and (.items[0].id | length) == 64
        and .items[0].subtitle == "3f9c1a7e2b4d"
        and all(.items[]; ((keys - ["autoUpdate","autoUpdateActive"]) | sort) == ["groups","id","rows","running","source","status","subtitle","title"])
    '
}

@test "status is the capitalized state and running is true only for running containers" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): [.status, .running]}] | add) == {
            "db": ["Running", true],
            "db-backup": ["Exited", false],
            "ghost": ["Created", false],
            "old-build": ["Exited", false],
            "scratch": ["Running", true],
            "worker": ["Paused", false]
        }
    '
}

@test "rows: image, command, state, health, ports and created" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.title == "db") | .rows) == [
            {"id":"image","label":"Image","value":"docker.io/library/postgres:16"},
            {"id":"command","label":"Command","value":"postgres"},
            {"id":"state","label":"State","value":"Up 3 days (healthy)"},
            {"id":"health","label":"Health","value":"Healthy"},
            {"id":"ports","label":"Ports","value":"127.0.0.1:5432 → 5432/tcp"},
            {"id":"created","label":"Created","value":"2026-11-08T09:12:00Z"}
        ]
        and (.items[] | select(.title == "scratch") | .rows[] | select(.id == "ports") | .value) == "0.0.0.0:8080-8081 → 80-81/tcp"
        and (.items[] | select(.title == "scratch") | .rows[] | select(.id == "command") | .value) == "sh -c \u0027sleep infinity\u0027"
        and (.items[] | select(.title == "ghost") | .rows[] | select(.id == "command") | .value) == "echo \u0027hello world\u0027"
        and (.items[] | select(.title == "old-build") | .rows[] | select(.id == "state") | .value) == "Exited"
        and ([.items[] | select(.title == "worker") | .rows[].id] == ["image","command","state","created"])
    '
}

@test "source: quadlet from the Quadlet map or a .container unit file, unit, else unmanaged" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): .source}] | add) == {
            "db": "quadlet",
            "db-backup": "unit",
            "ghost": "unmanaged",
            "old-build": "unmanaged",
            "scratch": "unmanaged",
            "worker": "quadlet"
        }
    '
}

@test "auto-update: policy from the label, active only when its unit is active" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): [.autoUpdate, .autoUpdateActive]}] | add) == {
            "db": ["registry", true],
            "db-backup": [null, null],
            "ghost": [null, null],
            "old-build": [null, null],
            "scratch": ["registry", false],
            "worker": ["local", true]
        }
        and ([.items[] | {(.title): (.groups[0].rows[] | select(.id == "auto-update") | .value)}] | add) == {
            "db": "Registry", "db-backup": "Off", "ghost": "Off", "old-build": "Off", "scratch": "Registry", "worker": "Local"
        }
    '
}

@test "details: networks, volumes, restart, and CPU and memory only for running containers" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.title == "db") | .groups[0].rows) == [
            {"id":"networks","label":"Networks","value":"shop-net"},
            {"id":"volumes","label":"Volumes","value":"pgdata → /var/lib/postgresql/data"},
            {"id":"auto-update","label":"Auto-update","value":"Registry"},
            {"id":"restart","label":"Restart policy","value":"no"},
            {"id":"cpu","label":"CPU","value":"1.20%"},
            {"id":"memory","label":"Memory","value":"84.2 MB"}
        ]
        and ((.items[] | select(.title == "scratch") | .groups[0].rows) == [
            {"id":"networks","label":"Networks","value":"pasta"},
            {"id":"volumes","label":"Volumes","value":"~/work → /work"},
            {"id":"auto-update","label":"Auto-update","value":"Registry"},
            {"id":"restart","label":"Restart policy","value":"no"},
            {"id":"cpu","label":"CPU","value":"0.00%"},
            {"id":"memory","label":"Memory","value":"1.09 MB"}
        ])
        and ([.items[] | select(.title == "worker") | .groups[0].rows[] | select(.id == "cpu" or .id == "memory")] == [])
        and ((.items[] | select(.title == "worker") | .groups[0].rows[] | select(.id == "restart") | .value) == "on-failure")
        and ((.items[] | select(.title == "old-build") | .groups[0].rows[0].value) == "slirp4netns")
    '
}

@test "systemd group: unit, state, file and app for quadlet and unit sources only" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" "${STATS}" /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.title == "db") | .groups[1]) == {"id":"systemd","label":"Systemd","rows":[
            {"id":"unit","label":"Unit name","value":"db.service"},
            {"id":"unit_state","label":"Unit state","value":"active"},
            {"id":"file","label":"File","value":"~/.config/containers/systemd/shop.qdl-bundle/db.container"},
            {"id":"app","label":"App","value":"shop"}
        ]}
        and ((.items[] | select(.title == "db-backup") | .groups[1].rows) == [
            {"id":"unit","label":"Unit name","value":"db-backup.service"},
            {"id":"unit_state","label":"Unit state","value":"inactive"},
            {"id":"file","label":"File","value":"~/.config/systemd/user/db-backup.service"}
        ])
        and ([.items[] | select(.source == "unmanaged") | .groups[].id] | unique) == ["details"]
    '
}

@test "missing stats leave CPU and memory out, and odd stats values are ignored" {
    run cockpit-containers-items "${PS}" "${INSPECT}" "${QUADLETS}" "${UNITS}" '[]' /home/podshift
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '[.items[].groups[].rows[] | select(.id == "cpu" or .id == "memory")] == []'
    run cockpit-containers-items '[{"Id":"abc","Names":["x"],"State":"running"}]' '[]' '{}' '{}' '[{"id":"abc","CPU":2.345,"mem_usage":"lots"}]' ''
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[0].groups[0].rows | map({(.id): .value}) | add) == {"auto-update":"Off","restart":"no","cpu":"2.35%"}
    '
}

@test "empty input gives no items" {
    run cockpit-containers-items '[]' '' '' '' '' ''
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
}

@test "arguments that are not the expected JSON return 1" {
    run cockpit-containers-items 'not json' '[]' '{}' '{}' '[]' ''
    [ "${status}" -eq 1 ]
    run cockpit-containers-items '{}' '[]' '{}' '{}' '[]' ''
    [ "${status}" -eq 1 ]
    run cockpit-containers-items '[]' '[]' '{}' '{}' '{}' ''
    [ "${status}" -eq 1 ]
}

@test "the podman ps state wins, and stopped from podman inspect is shown as Exited" {
    run cockpit-containers-items '[{"Id":"x1","Names":["a"]},{"Id":"x2","Names":["b"],"State":"running"}]' \
        '[{"Id":"x1","State":{"Status":"stopped"}},{"Id":"x2","State":{"Status":"stopped"}}]' '{}' '{}' '[]' ''
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.title): [.status, .running]}] | add) == {"a": ["Exited", false], "b": ["Running", true]}
        and (.items[0].rows[] | select(.id == "state") | .value) == "Exited"
    '
}
