#!/usr/bin/env bats
# Unit test for cockpit-networks-quadlet-name (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-networks-quadlet-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-networks-quadlet-name.sh"
}

@test "NetworkName in the Network section is used" {
    run cockpit-networks-quadlet-name "tsv-nw1.network" $'[Network]\nNetworkName=tsv-nw1\nSubnet=10.89.0.0/24\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "tsv-nw1" ]
}

@test "without NetworkName the name is systemd-<base>" {
    run cockpit-networks-quadlet-name "/home/podshift/.config/containers/systemd/shop.qdl-bundle/backend.network" $'[Network]\nSubnet=10.90.0.0/24\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "systemd-backend" ]
}

@test "the last NetworkName wins, spaces and quotes are trimmed" {
    run cockpit-networks-quadlet-name "a.network" $'[Network]\nNetworkName=first\n  NetworkName = "second"  \n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "second" ]
}

@test "NetworkName outside the Network section and in comments is ignored" {
    run cockpit-networks-quadlet-name "b.network" $'[Unit]\nNetworkName=wrong\n[Network]\n# NetworkName=commented\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "systemd-b" ]
}

@test "an empty file name returns 1" {
    run cockpit-networks-quadlet-name "" "[Network]"
    [ "${status}" -eq 1 ]
}
