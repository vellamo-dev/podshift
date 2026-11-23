#!/usr/bin/env bats
# Unit test for find-quadlet-users (src/server/opt/podshift/fn/quadlet/find-quadlet-users.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/find-quadlet-users.sh"
    Q="${BATS_TEST_TMPDIR}/systemd"
    mkdir -p "${Q}/shop"
    printf '[Network]\nNetworkName=front\n' > "${Q}/front.network"
    printf '[Container]\nNetwork=front.network\n' > "${Q}/web.container"
    printf '[Container]\nNetwork=front.network\nVolume=db.volume:/var/lib/db\n' > "${Q}/shop/api.container"
    printf '[Volume]\nVolumeName=db\n' > "${Q}/shop/db.volume"
}

@test "every installed user of a file is printed, relative and sorted" {
    run find-quadlet-users "${Q}" "${Q}/front.network" front.network
    [ "${status}" -eq 0 ]
    [ "${output}" = "shop/api.container"$'\n'"web.container" ]
}

@test "files of the app being removed may use each other" {
    run find-quadlet-users "${Q}" "${Q}/shop/" api.container db.volume
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "a file with no users returns 1" {
    run find-quadlet-users "${Q}" "${Q}/web.container" web.container
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "no names or a missing directory returns 1" {
    run find-quadlet-users "${Q}" "${Q}/web.container"
    [ "${status}" -eq 1 ]
    run find-quadlet-users "${Q}/nope" "" front.network
    [ "${status}" -eq 1 ]
}

@test "plain network, volume and mount names count as users" {
    printf '[Volume]\nVolumeName=data\n' > "${Q}/data.volume"
    printf '[Container]\nNetwork=front\n' > "${Q}/net.container"
    printf '[Container]\nVolume=data:/x\n' > "${Q}/vol.container"
    printf '[Container]\nMount=type=volume,source=data,destination=/m\n' > "${Q}/mnt.container"
    printf '[Container]\nNetwork=host\nVolume=/srv/x:/x\n' > "${Q}/none.container"
    run find-quadlet-users "${Q}" "${Q}/data.volume" data.volume
    [ "${status}" -eq 0 ]
    [ "${output}" = "mnt.container"$'\n'"vol.container" ]
    run find-quadlet-users "${Q}" "${Q}/front.network" front.network
    [ "${status}" -eq 0 ]
    [ "${output}" = "net.container"$'\n'"shop/api.container"$'\n'"web.container" ]
}
