#!/usr/bin/env bats
# Unit test for cockpit-overview-ssh-port (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-ssh-port.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-ssh-port.sh"
}

@test "one port is printed" {
    run cockpit-overview-ssh-port $'port 1022\npasswordauthentication no\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1022" ]
}

@test "several ports are unique and sorted" {
    run cockpit-overview-ssh-port $'port 1022\nport 22\nport 1022\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "22, 1022" ]
}

@test "capitalised Port lines are read" {
    run cockpit-overview-ssh-port $'Port 22\nPort 1022\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "22, 1022" ]
}

@test "no port returns 1" {
    run cockpit-overview-ssh-port $'passwordauthentication no\n'
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "empty text returns 1" {
    run cockpit-overview-ssh-port ""
    [ "${status}" -eq 1 ]
}
