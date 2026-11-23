#!/usr/bin/env bats
# Unit test for format-uuid7 (src/server/opt/podshift/fn/utils/format-uuid7.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/format-uuid7.sh"
}

@test "the time is the first 48 bits and the version is 7" {
    run format-uuid7 1700000000000 00000000000000000000
    [ "${status}" -eq 0 ]
    [ "${output}" = "018bcfe5-6800-7000-8000-000000000000" ]
}

@test "the variant bits are 10 and the random digits fill the rest" {
    run format-uuid7 1700000000000 ffffffffffffffffffff
    [ "${output}" = "018bcfe5-6800-7fff-bfff-ffffffffffff" ]
    run format-uuid7 1700000000000 0123456789ABCDEF0123
    [ "${output}" = "018bcfe5-6800-7012-b456-789abcdef012" ]
}

@test "the format, version and variant digits are right" {
    run format-uuid7 1763719200123 a1b2c3d4e5f60718293a
    [ "${status}" -eq 0 ]
    [[ "${output}" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]
}

@test "a later time sorts after an earlier one as text" {
    local a b
    a="$(format-uuid7 1763719200123 ffffffffffffffffffff)"
    b="$(format-uuid7 1763719200124 00000000000000000000)"
    [[ "${a}" < "${b}" ]]
}

@test "a bad time or random hex is refused" {
    run format-uuid7 "" 00000000000000000000
    [ "${status}" -eq 1 ]
    run format-uuid7 12a 00000000000000000000
    [ "${status}" -eq 1 ]
    run format-uuid7 281474976710656 00000000000000000000
    [ "${status}" -eq 1 ]
    run format-uuid7 1700000000000 0000000000000000000
    [ "${status}" -eq 1 ]
    run format-uuid7 1700000000000 g0000000000000000000
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "the largest 48-bit time is accepted" {
    run format-uuid7 281474976710655 00000000000000000000
    [ "${output}" = "ffffffff-ffff-7000-8000-000000000000" ]
}
