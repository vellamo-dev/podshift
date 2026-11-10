#!/usr/bin/env bats
# Unit test for health-route (src/server/opt/podshift/cli/modules/health-check/fn/health-route.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/fn/health-route.sh"
}

# $1 run-as, $2 caller, $3 expected output
check() {
    run health-route "${1}" "${2}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${3}" ]
}

# The any realm always routes direct, regardless of caller.
@test "any runs directly for every caller" {
    check any root direct
    check any podshift direct
    check any other direct
}

# The podshift realm maps each caller to its route.
@test "podshift: direct as podshift, session as root, skipped otherwise" {
    check podshift podshift direct
    check podshift root podshift-session
    check podshift other skip-podshift
}

# The root realm is direct only for root, skipped otherwise.
@test "root: direct as root, skipped otherwise" {
    check root root direct
    check root podshift skip-root
    check root other skip-root
}

# An unknown or empty realm is invalid.
@test "unknown or empty realm is invalid" {
    check admin root invalid
    check "" root invalid
}
