#!/usr/bin/env bats
# Unit test for cockpit-volumes-quadlet-name (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-volumes-quadlet-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-volumes-quadlet-name.sh"
}

@test "VolumeName in the Volume section is used" {
    run cockpit-volumes-quadlet-name "pgdata.volume" $'[Volume]\nVolumeName=pgdata\nLabel=a=b\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "pgdata" ]
}

@test "without VolumeName the name is systemd-<base>" {
    run cockpit-volumes-quadlet-name "/home/podshift/.config/containers/systemd/shop.qdl-bundle/data.volume" $'[Volume]\nDriver=local\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "systemd-data" ]
}

@test "the last VolumeName wins, spaces and quotes are trimmed" {
    run cockpit-volumes-quadlet-name "a.volume" $'[Volume]\nVolumeName=first\n  VolumeName = "second"  \n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "second" ]
}

@test "VolumeName outside the Volume section and in comments is ignored" {
    run cockpit-volumes-quadlet-name "b.volume" $'[Unit]\nVolumeName=wrong\n[Volume]\n# VolumeName=commented\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "systemd-b" ]
}

@test "an empty file name returns 1" {
    run cockpit-volumes-quadlet-name "" "[Volume]"
    [ "${status}" -eq 1 ]
}
