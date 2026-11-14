#!/usr/bin/env bats
# Unit test for cockpit-overview-unit-state (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-unit-state.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-unit-state.sh"
}

@test "active running is Running" {
    run cockpit-overview-unit-state active running
    [ "${status}" -eq 0 ]
    [ "${output}" = "Running" ]
}

@test "active listening is Running" {
    run cockpit-overview-unit-state active listening
    [ "${status}" -eq 0 ]
    [ "${output}" = "Running" ]
}

@test "active waiting is Waiting" {
    run cockpit-overview-unit-state active waiting
    [ "${status}" -eq 0 ]
    [ "${output}" = "Waiting" ]
}

@test "active exited is Exited" {
    run cockpit-overview-unit-state active exited
    [ "${status}" -eq 0 ]
    [ "${output}" = "Exited" ]
}

@test "inactive is Stopped" {
    run cockpit-overview-unit-state inactive dead
    [ "${status}" -eq 0 ]
    [ "${output}" = "Stopped" ]
}

@test "failed is Failed" {
    run cockpit-overview-unit-state failed failed
    [ "${status}" -eq 0 ]
    [ "${output}" = "Failed" ]
}

@test "activating is Starting" {
    run cockpit-overview-unit-state activating start-pre
    [ "${status}" -eq 0 ]
    [ "${output}" = "Starting" ]
}

@test "deactivating is Stopping" {
    run cockpit-overview-unit-state deactivating stop
    [ "${status}" -eq 0 ]
    [ "${output}" = "Stopping" ]
}

@test "reloading is Reloading" {
    run cockpit-overview-unit-state reloading reload
    [ "${status}" -eq 0 ]
    [ "${output}" = "Reloading" ]
}

@test "empty state returns 1" {
    run cockpit-overview-unit-state "" ""
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
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
