#!/usr/bin/env bats
# Unit test for list-tsv-vars (src/server/opt/podshift/fn/quadlet/list-tsv-vars.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/list-tsv-vars.sh"
    Q="${BATS_TEST_TMPDIR}/app.container"
}

# No TSV vars yields no output.
@test "no variables prints nothing and returns 0" {
    printf '[Container]\nImage=nginx\n' > "${Q}"
    run list-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

# A var is printed without the braces.
@test "one variable prints its name without the braces" {
    printf 'Image=nginx:${TSV_VERSION}\n' > "${Q}"
    run list-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "TSV_VERSION" ]
}

# Repeated vars are deduplicated.
@test "a repeated variable is listed once" {
    printf 'A=${TSV_A}\nB=${TSV_A}/x/${TSV_A}\n' > "${Q}"
    run list-tsv-vars "${Q}"
    [ "${output}" = "TSV_A" ]
}

# Vars are sorted, one per line, deduplicated.
@test "several variables are sorted, one per line, also several on one line" {
    printf 'A=${TSV_NW2}\nB=${TSV_ENV}:${TSV_NW1}\nC=${TSV_ENV}\n' > "${Q}"
    run list-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'TSV_ENV\nTSV_NW1\nTSV_NW2' ]
}

# Only TSV_ vars match.
@test "other variables and specifiers are not listed" {
    printf 'A=${OTHER}\nB=$TSV_X\nC=%%h\nD=${TSV_OK}\nE=${tsv_x}\nF=${TSV_BAD\n' > "${Q}"
    run list-tsv-vars "${Q}"
    [ "${output}" = "TSV_OK" ]
}

# The function lists names, not resolved values.
@test "unknown names are listed too, the function does not look at values" {
    printf 'A=${TSV_NOT_SET_ANYWHERE}\n' > "${Q}"
    run list-tsv-vars "${Q}"
    [ "${output}" = "TSV_NOT_SET_ANYWHERE" ]
}

# A missing file fails silently.
@test "missing file returns 1 and prints nothing" {
    run list-tsv-vars "${BATS_TEST_TMPDIR}/nope.container"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
