#!/usr/bin/env bats
# Unit test for cockpit-request-limit (src/server/opt/podshift/cockpit/api/fn/cockpit-request-limit.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/cockpit-request-limit.sh"
}

@test "quadlet-drop may send 131072 bytes" {
    run cockpit-request-limit quadlet-drop
    [ "${status}" -eq 0 ]
    [ "${output}" = "131072" ]
}

@test "other actions keep 65536 bytes" {
    run cockpit-request-limit config-set
    [ "${output}" = "65536" ]
    run cockpit-request-limit quadlet-drop-history
    [ "${output}" = "65536" ]
}

@test "an empty or unknown name keeps 65536 bytes" {
    run cockpit-request-limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "65536" ]
    run cockpit-request-limit "../quadlet-drop"
    [ "${output}" = "65536" ]
}
