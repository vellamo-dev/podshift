#!/usr/bin/env bats
# Unit test for cockpit-overview-count (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-count.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-count.sh"
}

@test "formats two counts" {
    run cockpit-overview-count 3 5
    [ "${status}" -eq 0 ]
    [ "${output}" = "3 / 5" ]
}

@test "zero counts are printed as 0" {
    run cockpit-overview-count 0 0
    [ "${status}" -eq 0 ]
    [ "${output}" = "0" ]
}

@test "a zero in-use count keeps the total" {
    run cockpit-overview-count 0 3
    [ "${status}" -eq 0 ]
    [ "${output}" = "0 / 3" ]
}

@test "one count is printed as the total" {
    run cockpit-overview-count 3
    [ "${status}" -eq 0 ]
    [ "${output}" = "3" ]
}

@test "a zero total is allowed" {
    run cockpit-overview-count 0
    [ "${status}" -eq 0 ]
    [ "${output}" = "0" ]
}

@test "a non-integer returns 1" {
    run cockpit-overview-count 3 x
    [ "${status}" -eq 1 ]
}

@test "a missing argument returns 1" {
    run cockpit-overview-count
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
