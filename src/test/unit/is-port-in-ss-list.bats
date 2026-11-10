#!/usr/bin/env bats
# Unit test for is-port-in-ss-list (src/server/opt/podshift/fn/network/is-port-in-ss-list.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/network/is-port-in-ss-list.sh"
    SS_BOTH=$'State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process\nLISTEN 0      128          0.0.0.0:22        0.0.0.0:*\nLISTEN 0      128          0.0.0.0:1022      0.0.0.0:*\nLISTEN 0      128             [::]:22           [::]:*\nLISTEN 0      128             [::]:1022         [::]:*'
    SS_ONLY22=$'State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process\nLISTEN 0      128          0.0.0.0:22        0.0.0.0:*\nLISTEN 0      128             [::]:22           [::]:*'
}

# The local address column is matched.
@test "a listed port returns 0 and prints nothing" {
    run is-port-in-ss-list "${SS_BOTH}" 1022
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    run is-port-in-ss-list "${SS_BOTH}" 22
    [ "${status}" -eq 0 ]
}

@test "a port that is not listed returns 1" {
    run is-port-in-ss-list "${SS_ONLY22}" 1022
    [ "${status}" -eq 1 ]
}

# The port must match exactly.
@test "1022 does not match 10220 or 21022" {
    run is-port-in-ss-list $'LISTEN 0 128 0.0.0.0:10220 0.0.0.0:*\nLISTEN 0 128 0.0.0.0:21022 0.0.0.0:*' 1022
    [ "${status}" -eq 1 ]
}

# Only IPv6 listeners count too.
@test "an IPv6 only listener matches" {
    run is-port-in-ss-list $'LISTEN 0 128 [::]:1022 [::]:*' 1022
    [ "${status}" -eq 0 ]
}

# A port in the peer column does not count.
@test "a port in the peer address column does not match" {
    run is-port-in-ss-list $'LISTEN 0 128 0.0.0.0:22 10.0.0.1:1022' 1022
    [ "${status}" -eq 1 ]
}

@test "empty output or empty port returns 1" {
    run is-port-in-ss-list "" 1022
    [ "${status}" -eq 1 ]
    run is-port-in-ss-list "${SS_BOTH}" ""
    [ "${status}" -eq 1 ]
    run is-port-in-ss-list
    [ "${status}" -eq 1 ]
}
