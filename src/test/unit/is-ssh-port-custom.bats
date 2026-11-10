#!/usr/bin/env bats
# Unit test for is-ssh-port-custom (src/server/opt/podshift/fn/network/is-ssh-port-custom.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/network/is-ssh-port-custom.sh"
}

# Only allowed ports means no custom port.
@test "port 22 alone with 22 allowed returns 1" {
    run is-ssh-port-custom $'Port 22\nlistenaddress 0.0.0.0' "22"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "ports 22 and 1022 with both allowed return 1" {
    run is-ssh-port-custom $'Port 22\nPort 1022' "22 1022"
    [ "${status}" -eq 1 ]
}

# Any port outside the list is custom.
@test "port 2222 returns 0" {
    run is-ssh-port-custom $'Port 2222' "22 1022"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "port 1022 with only 22 allowed returns 0" {
    run is-ssh-port-custom $'Port 22\nPort 1022' "22"
    [ "${status}" -eq 0 ]
}

@test "one custom port among allowed ports returns 0" {
    run is-ssh-port-custom $'Port 22\nPort 2222\nPort 1022' "22 1022"
    [ "${status}" -eq 0 ]
}

# Ports match whole numbers, not parts of them.
@test "port 222 is not matched by the allowed 22" {
    run is-ssh-port-custom $'Port 222' "22 1022"
    [ "${status}" -eq 0 ]
}

# No port line means nothing custom.
@test "empty output or no port line returns 1" {
    run is-ssh-port-custom "" "22 1022"
    [ "${status}" -eq 1 ]
    run is-ssh-port-custom $'permitrootlogin no\nlistenaddress 0.0.0.0' "22 1022"
    [ "${status}" -eq 1 ]
    run is-ssh-port-custom
    [ "${status}" -eq 1 ]
}
