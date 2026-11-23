#!/usr/bin/env bats
# Unit test for get-quadlet-unit-name (src/server/opt/podshift/fn/quadlet/get-quadlet-unit-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/get-quadlet-unit-name.sh"
}

@test "a container and a kube file keep the base name" {
    run get-quadlet-unit-name web.container
    [ "${status}" -eq 0 ]
    [ "${output}" = "web.service" ]
    run get-quadlet-unit-name app.kube
    [ "${output}" = "app.service" ]
}

@test "the other types get the type ending" {
    local t
    for t in pod network volume image build; do
        run get-quadlet-unit-name "web.${t}"
        [ "${status}" -eq 0 ]
        [ "${output}" = "web-${t}.service" ]
    done
}

@test "a folder and the collision suffix are removed first" {
    run get-quadlet-unit-name /home/podshift/.config/containers/systemd/shop/db.volume.1761612345123456789
    [ "${status}" -eq 0 ]
    [ "${output}" = "db-volume.service" ]
}

@test "an unknown extension or no base name returns 1" {
    run get-quadlet-unit-name notes.txt
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    run get-quadlet-unit-name .container
    [ "${status}" -eq 1 ]
    run get-quadlet-unit-name web
    [ "${status}" -eq 1 ]
}
