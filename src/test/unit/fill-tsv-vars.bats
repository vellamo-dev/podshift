#!/usr/bin/env bats
# Unit test for fill-tsv-vars (src/server/opt/podshift/fn/quadlet/fill-tsv-vars.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/fill-tsv-vars.sh"
    Q="${BATS_TEST_TMPDIR}/app.container"
    unset TSV_ENV TSV_NW1 TSV_NW2 TSV_VERSION TSV_A TSV_X TSV_P TSV_E TSV_KNOWN TSV_UNKNOWN TSV_Z OTHER
}

# No TSV vars: the file is left byte-for-byte unchanged.
@test "no variables leaves the file as it was" {
    printf '[Container]\nImage=nginx\n' > "${Q}"
    TSV_ENV=dev
    run fill-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    [ "$(cat "${Q}")" = $'[Container]\nImage=nginx' ]
}

# A single var is substituted inline.
@test "one variable is filled in place" {
    printf 'Image=nginx:${TSV_VERSION}\n' > "${Q}"
    TSV_VERSION=16
    run fill-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    [ "$(cat "${Q}")" = "Image=nginx:16" ]
}

# Every occurrence is substituted, not just the first.
@test "a repeated variable is filled everywhere" {
    printf 'A=${TSV_A}\nB=${TSV_A}-${TSV_A}\n' > "${Q}"
    TSV_A=x
    fill-tsv-vars "${Q}"
    [ "$(cat "${Q}")" = $'A=x\nB=x-x' ]
}

# Multiple vars on one line are all filled.
@test "several variables are filled" {
    printf 'A=${TSV_ENV}\nB=${TSV_NW1} ${TSV_NW2}\n' > "${Q}"
    TSV_ENV=prod
    TSV_NW1=10.0.0.1
    TSV_NW2=10.0.0.2
    fill-tsv-vars "${Q}"
    [ "$(cat "${Q}")" = $'A=prod\nB=10.0.0.1 10.0.0.2' ]
}

# An unset var stays literal so the file still installs and reports it.
@test "an unset variable is left as is" {
    printf 'A=${TSV_KNOWN}\nB=${TSV_UNKNOWN}\n' > "${Q}"
    TSV_KNOWN=1
    run fill-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${Q}")" = $'A=1\nB=${TSV_UNKNOWN}' ]
}

# An empty-but-set var is left literal, not treated as set.
@test "an empty variable is left as is" {
    printf 'A=${TSV_E}\n' > "${Q}"
    TSV_E=""
    fill-tsv-vars "${Q}"
    [ "$(cat "${Q}")" = 'A=${TSV_E}' ]
}

# Only TSV_ vars are touched; other vars and %-specifiers stay.
@test "other variables and specifiers are untouched, even if set" {
    printf 'A=${OTHER}\nB=$TSV_X\nC=%%h/%%n\nD=${TSV_X}\nE=${tsv_x}\n' > "${Q}"
    TSV_X=v
    OTHER=no
    tsv_x=no
    fill-tsv-vars "${Q}"
    [ "$(cat "${Q}")" = $'A=${OTHER}\nB=$TSV_X\nC=%h/%n\nD=v\nE=${tsv_x}' ]
}

# Values are inserted verbatim, no shell quoting.
@test "special characters in a value are inserted literally" {
    printf 'A=${TSV_P}\n' > "${Q}"
    TSV_P='a/b&c\1|d$HOME`x`"e" it'"'"'s %h *'
    run fill-tsv-vars "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${Q}")" = 'A=a/b&c\1|d$HOME`x`"e" it'"'"'s %h *' ]
}

# Single-pass: a value containing a var is not re-expanded.
@test "an inserted value is not scanned again" {
    printf 'A=${TSV_P}\n' > "${Q}"
    TSV_P='${TSV_Z}'
    TSV_Z=no
    fill-tsv-vars "${Q}"
    [ "$(cat "${Q}")" = 'A=${TSV_Z}' ]
}

# Values are never eval'd or command-substituted (security).
@test "a value is never evaluated" {
    printf 'A=${TSV_X}\n' > "${Q}"
    TSV_X="\$(touch ${BATS_TEST_TMPDIR}/pwned)"
    fill-tsv-vars "${Q}"
    [ ! -e "${BATS_TEST_TMPDIR}/pwned" ]
    [ "$(cat "${Q}")" = "A=\$(touch ${BATS_TEST_TMPDIR}/pwned)" ]
}

# A missing trailing newline is preserved.
@test "the final newline state of the file is kept" {
    printf 'A=${TSV_X}' > "${Q}"
    TSV_X=1
    fill-tsv-vars "${Q}"
    [ "$(cat "${Q}"; printf x)" = "A=1x" ]
}

# No-op files keep their mtime (no needless rewrite).
@test "a file with nothing to fill is not rewritten" {
    printf 'A=${TSV_UNKNOWN}\n' > "${Q}"
    touch -t 200001010000 "${Q}"
    before="$(ls -l "${Q}")"
    fill-tsv-vars "${Q}"
    [ "$(ls -l "${Q}")" = "${before}" ]
}

# A missing file fails silently.
@test "missing quadlet file returns 1 and prints nothing" {
    run fill-tsv-vars "${BATS_TEST_TMPDIR}/nope.container"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

# Missing argument fails silently.
@test "no file argument returns 1 and prints nothing" {
    run fill-tsv-vars
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
