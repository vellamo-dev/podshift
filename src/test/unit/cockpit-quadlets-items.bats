#!/usr/bin/env bats
# Unit test for cockpit-quadlets-items (src/server/opt/podshift/cockpit/api/fn/quadlets/cockpit-quadlets-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/quadlets/cockpit-quadlets-items.sh"
    FIXTURES="${BATS_TEST_DIRNAME}/fixtures/cockpit-quadlets"
}

@test "maps podman PascalCase fields, drops a known suffix from the title and adds type" {
    run cockpit-quadlets-items '[{"Name":"shop-api.container","UnitName":"shop-api.service","Path":"/home/podshift/.config/containers/systemd/shop/shop-api.container","Status":"active/running","App":"shop","Pod":"shop.pod"}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '. == {"items":[{"id":"shop-api.container","title":"shop-api","type":"container","unitName":"shop-api.service","path":"/home/podshift/.config/containers/systemd/shop/shop-api.container","status":"active/running","app":"shop","pod":"shop.pod","description":""}]}'
}

@test "empty array and null become {items:[]}" {
    run cockpit-quadlets-items '[]'
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
    run cockpit-quadlets-items 'null'
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
    run cockpit-quadlets-items ''
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
}

@test "missing App, Pod or UnitName become empty strings; type is left out when the suffix is unknown" {
    run cockpit-quadlets-items '[{"Name":"custom.file","Path":"/tmp/custom.file","Status":"Not loaded"}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '. == {"items":[{"id":"custom.file","title":"custom.file","unitName":"","path":"/tmp/custom.file","status":"Not loaded","app":"","pod":"","description":""}]}'
    printf '%s' "${output}" | jq -e '.items[0] | has("type") | not'
}

@test "entries with no name are skipped; items are sorted by title then id" {
    run cockpit-quadlets-items '[{"Name":"shop.pod","UnitName":"shop-pod.service","Path":"/a/shop.pod","Status":"active/running","App":"shop","Pod":""},{"Name":"","Path":"/a/empty","Status":"inactive/dead"},{"Name":"shop.network","UnitName":"shop-network.service","Path":"/a/shop.network","Status":"inactive/dead","App":"shop","Pod":""}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '[.items[].id] == ["shop.network","shop.pod"] and .items[0].title == "shop" and .items[1].title == "shop" and .items[0].type == "network" and .items[1].type == "pod"'
}

@test "maps the sample listing fixture, including every known suffix" {
    raw="$(cat "${FIXTURES}/ls-ok.json")"
    run cockpit-quadlets-items "${raw}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].id] == ["backup.kube","cache.image","shop.network","shop.pod","shop-api.container","shop-db.volume","web.container","zz-quadlet-test.container"]
        and .items[0].title == "backup" and .items[0].type == "kube" and .items[0].status == "failed/failed"
        and .items[1].title == "cache" and .items[1].type == "image" and .items[1].status == "Not loaded"
        and .items[2].title == "shop" and .items[2].type == "network"
        and .items[3].title == "shop" and .items[3].type == "pod"
        and .items[4].title == "shop-api" and .items[4].type == "container" and .items[4].app == "shop" and .items[4].pod == "shop.pod"
        and .items[5].title == "shop-db" and .items[5].type == "volume"
        and .items[6].title == "web" and .items[6].type == "container" and .items[6].unitName == "web.service"
        and .items[7].title == "zz-quadlet-test" and .items[7].type == "container"
        and ([.items[].description] | all(. == ""))
        and (.items | length) == 8
    '
}

@test "an object, a string or invalid JSON is refused" {
    run cockpit-quadlets-items '{}'
    [ "${status}" -eq 1 ]
    run cockpit-quadlets-items '"nope"'
    [ "${status}" -eq 1 ]
    run cockpit-quadlets-items 'not-json'
    [ "${status}" -eq 1 ]
}

@test "reads the first Description= from the [Unit] section of the quadlet file" {
    QDL="${BATS_TEST_TMPDIR}/web.container"
    printf '[Unit]\nDescription=  Shop web frontend  \nDescription=Second\n[Container]\nDescription=ignored\nImage=web\n' > "${QDL}"
    raw="$(jq -nc --arg p "${QDL}" '[{Name:"web.container",UnitName:"web.service",Path:$p,Status:"active/running",App:"",Pod:""}]')"
    run cockpit-quadlets-items "${raw}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e --arg path "${QDL}" '.items | length == 1 and .[0].description == "Shop web frontend" and .[0].path == $path'
}

@test "a file with no unit Description, or only one in another section, yields an empty description" {
    QDL="${BATS_TEST_TMPDIR}/plain.container"
    printf '[Unit]\nAfter=network.target\n[Container]\nDescription=not the unit\nImage=web\n' > "${QDL}"
    raw="$(jq -nc --arg p "${QDL}" '[{Name:"plain.container",Path:$p,Status:"Not loaded"}]')"
    run cockpit-quadlets-items "${raw}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].description == ""'

    printf '[Unit]\nDescription=\n[Container]\nImage=web\n' > "${QDL}"
    raw="$(jq -nc --arg p "${QDL}" '[{Name:"plain.container",Path:$p,Status:"Not loaded"}]')"
    run cockpit-quadlets-items "${raw}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].description == ""'
}

@test "a missing or unreadable quadlet file yields an empty description" {
    run cockpit-quadlets-items '[{"Name":"gone.container","Path":"/no/such/gone.container","Status":"Not loaded"}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].description == ""'

    QDL="${BATS_TEST_TMPDIR}/locked.container"
    printf '[Unit]\nDescription=Secret\n' > "${QDL}"
    chmod 000 "${QDL}"
    raw="$(jq -nc --arg p "${QDL}" '[{Name:"locked.container",Path:$p,Status:"Not loaded"}]')"
    run cockpit-quadlets-items "${raw}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].description == ""'
    chmod 644 "${QDL}"
}
