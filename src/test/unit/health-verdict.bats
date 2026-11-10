#!/usr/bin/env bats
# Unit test for health-verdict (src/server/opt/podshift/cli/modules/health-check/fn/health-verdict.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/fn/health-verdict.sh"
}

# One result line: $1 status
line() {
    printf 'g\tid\ttitle\t%s\tdetail' "${1}"
}

# $1 result lines, $2 expected: verdict passed issues warnings errors skipped notes (space separated)
check() {
    run health-verdict "${1}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%s' "${2}" | tr ' ' '\t')" ]
}

# All OK results sum to healthy.
@test "all OK is healthy" {
    check "$(line OK)"$'\n'"$(line OK)" "healthy 2 0 0 0 0 0"
}

# INFO (notes) and SKIP are counted but do not change healthy.
@test "INFO and SKIP are counted and stay healthy" {
    check "$(line OK)"$'\n'"$(line INFO)"$'\n'"$(line SKIP)" "healthy 1 0 0 0 1 1"
}

# A WARN raises the verdict to needs-attention.
@test "a warning needs attention" {
    check "$(line OK)"$'\n'"$(line WARN)" "needs-attention 1 0 1 0 0 0"
}

# FAIL outranks WARN (issues-found).
@test "a failure beats a warning" {
    check "$(line FAIL)"$'\n'"$(line WARN)" "issues-found 0 1 1 0 0 0"
}

# An unknown status counts as an error and outranks FAIL (incomplete).
@test "an unknown status is an error and beats a failure" {
    check "$(line FAIL)"$'\n'"$(line ERROR)" "incomplete 0 1 0 1 0 0"
}
