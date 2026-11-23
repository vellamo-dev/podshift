#!/usr/bin/env bats
# Unit test for cockpit-overview-unit-state-from-show (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-unit-state-from-show.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-unit-state-from-show.sh"
}

@test "from-show maps a listening socket" {
    run cockpit-overview-unit-state-from-show $'LoadState=loaded\nActiveState=active\nSubState=listening\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Running" ]
}

@test "from-show returns 1 for a missing unit" {
    run cockpit-overview-unit-state-from-show $'LoadState=not-found\nActiveState=inactive\nSubState=dead\n'
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "from-show returns 1 for empty text" {
    run cockpit-overview-unit-state-from-show ""
    [ "${status}" -eq 1 ]
}
