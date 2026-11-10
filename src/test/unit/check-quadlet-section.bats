#!/usr/bin/env bats
# Unit test for check-quadlet-section (src/server/opt/podshift/fn/quadlet/check-quadlet-section.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/check-quadlet-section.sh"
    QDL="${BATS_TEST_TMPDIR}/app.container"
    printf '[Unit]\nDescription=App\n[Container]\nContainerName=app\nImage=\n[container]\nImage=x\n' > "${QDL}"
}

# Happy path: the section exists and every required key is present.
@test "section with all keys is valid and prints nothing" {
    run check-quadlet-section "${QDL}" app.container Unit Description
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

# A section with no required keys passes if it merely exists.
@test "section with no keys only needs to exist" {
    run check-quadlet-section "${QDL}" app.container Unit
    [ "${status}" -eq 0 ]
}

# An absent section fails with its name in the message.
@test "missing section" {
    run check-quadlet-section "${QDL}" app.container Install WantedBy
    [ "${status}" -eq 1 ]
    [ "${output}" = "app.container: missing [Install]" ]
}

# Section lookup is case-sensitive, matching systemd.
@test "section names are case-sensitive" {
    run check-quadlet-section "${QDL}" app.container Service
    [ "${status}" -eq 1 ]
    [ "${output}" = "app.container: missing [Service]" ]
}

# Empty and missing keys are both reported; keys are case-sensitive.
@test "empty and missing keys are listed together, key names case-sensitive" {
    run check-quadlet-section "${QDL}" app.container Container ContainerName Image containername
    [ "${status}" -eq 1 ]
    [ "${output}" = "app.container: [Container] missing Image, containername" ]
}

# A malformed line surfaces as bad line N, prefixed with the name.
@test "a bad line is reported with the name" {
    printf '[Unit]\nDescription\n' > "${QDL}"
    run check-quadlet-section "${QDL}" app.container Unit
    [ "${status}" -eq 1 ]
    [ "${output}" = "app.container: bad line 2" ]
}

# A missing file yields cannot read, prefixed with the name.
@test "an unreadable file is reported with the name" {
    run check-quadlet-section "${BATS_TEST_TMPDIR}/none.container" none.container Unit
    [ "${status}" -eq 1 ]
    [ "${output}" = "none.container: cannot read" ]
}

# An empty value is treated as an absent key.
@test "an empty value counts as missing" {
    printf '[Unit]\nDescription=\n' > "${QDL}"
    run check-quadlet-section "${QDL}" app.container Unit Description
    [ "${status}" -eq 1 ]
    [ "${output}" = "app.container: [Unit] missing Description" ]
}

# Whitespace-only values count as missing, listed in key order.
@test "a whitespace-only value counts as missing, listed in key order with missing keys" {
    printf '[Container]\nImage=   \t\nContainerName=app\n' > "${QDL}"
    run check-quadlet-section "${QDL}" app.container Container Name Image ContainerName
    [ "${status}" -eq 1 ]
    [ "${output}" = "app.container: [Container] missing Name, Image" ]
}
