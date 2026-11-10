#!/usr/bin/env bats
# Unit test for get-quadlet-ini (src/server/opt/podshift/fn/quadlet/get-quadlet-ini.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/get-quadlet-ini.sh"
    INI="${BATS_TEST_TMPDIR}/app.container"
    printf '# comment\n; comment\n\n[Unit]\n  Description = App one  \n[Container]\nImage=first\nEmpty=\nNetwork=x.network:ip=10.0.0.2\nPodmanArgs=--cpus 2 \\\n    --memory 512m\n[Unit]\nWants=x.network\n[container]\nimage=lower\n[Container]\nImage=last\n' > "${INI}"
}

# Lists sections, deduplicated, in first-seen order.
@test "no section lists each section once in first-seen order" {
    run get-quadlet-ini "${INI}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'Unit\nContainer\ncontainer' ]
}

# Lists a section's non-empty keys once; empty values are hidden.
@test "section lists its keys with a non-empty value once, empty value hidden" {
    run get-quadlet-ini "${INI}" Container
    [ "${status}" -eq 0 ]
    [ "${output}" = $'Image\nNetwork\nPodmanArgs' ]
}

# Returns the trimmed value; the last duplicate wins.
@test "section and key prints the trimmed value, last occurrence wins" {
    run get-quadlet-ini "${INI}" Container Image
    [ "${status}" -eq 0 ]
    [ "${output}" = "last" ]
    run get-quadlet-ini "${INI}" Unit Description
    [ "${output}" = "App one" ]
}

# Only the first equals sign splits key from value.
@test "value is split on the first equals sign" {
    run get-quadlet-ini "${INI}" Container Network
    [ "${output}" = "x.network:ip=10.0.0.2" ]
}

# Section and key names are case-sensitive, like systemd.
@test "sections and keys are case-sensitive" {
    run get-quadlet-ini "${INI}" container
    [ "${output}" = "image" ]
    run get-quadlet-ini "${INI}" container Image
    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
    run get-quadlet-ini "${INI}" CONTAINER
    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
}

# Empty and missing values fail silently.
@test "empty value and missing key return 1 with no output" {
    run get-quadlet-ini "${INI}" Container Empty
    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
    run get-quadlet-ini "${INI}" Unit Missing
    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
}

# A line with no equals sign is reported as bad line N.
@test "line without equals sign is a bad line" {
    printf '[Unit]\n\nDescription\n' > "${INI}"
    run get-quadlet-ini "${INI}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "bad line 3" ]
}

# An unterminated Section is reported as a bad line.
@test "broken section header is a bad line" {
    printf '[Unit]\nDescription=App\n[Unit\n' > "${INI}"
    run get-quadlet-ini "${INI}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "bad line 3" ]
}

# A equals-value line with an empty key is a bad line.
@test "empty key is a bad line" {
    printf '[Unit]\n=App\n' > "${INI}"
    run get-quadlet-ini "${INI}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "bad line 2" ]
}

# A key outside any section is a bad line.
@test "key before any section is a bad line" {
    printf '# head\nDescription=App\n[Unit]\n' > "${INI}"
    run get-quadlet-ini "${INI}" Unit
    [ "${status}" -eq 1 ]
    [ "${output}" = "bad line 2" ]
}

# A missing file fails with cannot read.
@test "missing file cannot be read" {
    run get-quadlet-ini "${BATS_TEST_TMPDIR}/none.container"
    [ "${status}" -eq 1 ]
    [ "${output}" = "cannot read" ]
}
