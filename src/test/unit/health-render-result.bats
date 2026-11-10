#!/usr/bin/env bats
# Unit test for health-render-result (src/server/opt/podshift/cli/modules/health-check/fn/health-render-result.sh).
# Run with: ./test unit-pure-functions

setup() {
    # Plain output, no colors, so the text is always the same.
    unset PODSHIFT_OUTPUT
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/fn/health-render-result.sh"
}

# $1 verdict line (space separated), $2 expected result line
check() {
    run health-render-result "$(printf '%s' "${1}" | tr ' ' '\t')"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'\n    Result:\n        '"${2}" ]
}

# Healthy prints the healthy line with the passed count.
@test "healthy" {
    check "healthy 3 0 0 0 0 0" "✔ Healthy (3 passed)"
}

# One warning prints the needs-attention line.
@test "needs attention, one warning" {
    check "needs-attention 0 0 1 0 0 0" "⚠ Needs attention (1 warning)"
}

# Counts are pluralized and singularized correctly.
@test "issues found, plural and singular counts" {
    check "issues-found 22 2 1 0 0 1" "✘ Issues found (22 passed, 2 issues, 1 warning, 1 note)"
}

# Errors and skipped are shown in the incomplete line.
@test "incomplete, with errors and skipped" {
    check "incomplete 1 0 0 2 1 0" "! Check incomplete (1 passed, 2 checks could not run, 1 skipped)"
}
