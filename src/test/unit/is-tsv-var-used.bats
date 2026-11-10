#!/usr/bin/env bats
# Unit test for is-tsv-var-used (src/server/opt/podshift/fn/quadlet/is-tsv-var-used.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/is-tsv-var-used.sh"
    Q="${BATS_TEST_TMPDIR}/app.container"
}

# No TSV var means unused.
@test "no variables returns 1 and prints nothing" {
    printf '[Container]\nImage=docker.io/library/nginx:1\n' > "${Q}"
    run is-tsv-var-used "${Q}"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

# One TSV var means used.
@test "one variable returns 0 and prints nothing" {
    printf '[Container]\nImage=nginx:${TSV_VERSION}\n' > "${Q}"
    run is-tsv-var-used "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

# Multiple or repeated vars still mean used.
@test "repeated and several variables return 0" {
    printf 'A=${TSV_A}\nB=${TSV_A}\nC=${TSV_B2}\n' > "${Q}"
    run is-tsv-var-used "${Q}"
    [ "${status}" -eq 0 ]
}

# Only TSV_ vars match; other vars and specifiers do not.
@test "other variables and specifiers are not TSV variables" {
    printf 'A=${OTHER}\nB=$TSV_X\nC=%%h/data\nD=${tsv_x}\nE=${TSV_}\nF=${TSV_X\n' > "${Q}"
    run is-tsv-var-used "${Q}"
    [ "${status}" -eq 1 ]
}

# A TSV var is found even among non-TSV vars.
@test "a TSV variable among other variables is found" {
    printf 'A=${OTHER}\nB=%%h\nC=${TSV_NW1}\n' > "${Q}"
    run is-tsv-var-used "${Q}"
    [ "${status}" -eq 0 ]
}

# A missing file returns false silently.
@test "missing file returns 1 and prints nothing" {
    run is-tsv-var-used "${BATS_TEST_TMPDIR}/nope.container"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
