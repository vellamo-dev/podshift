#!/usr/bin/env bats
# Unit test for is-valid-uuid7 (src/server/opt/podshift/fn/utils/is-valid-uuid7.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/is-valid-uuid7.sh"
}

@test "a lower-case UUIDv7 is valid" {
    run is-valid-uuid7 018bcfe5-6800-7012-b456-789abcdef012
    [ "${status}" -eq 0 ]
    run is-valid-uuid7 018bcfe5-6800-7000-8000-000000000000
    [ "${status}" -eq 0 ]
}

@test "another version, variant, upper case or shape is not valid" {
    local id
    for id in "" 018bcfe5-6800-4012-b456-789abcdef012 018bcfe5-6800-7012-c456-789abcdef012 \
        018BCFE5-6800-7012-B456-789ABCDEF012 018bcfe56800-7012-b456-789abcdef012 \
        018bcfe5-6800-7012-b456-789abcdef0123 " 018bcfe5-6800-7012-b456-789abcdef012"; do
        run is-valid-uuid7 "${id}"
        [ "${status}" -eq 1 ]
    done
}
