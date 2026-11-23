#!/usr/bin/env bats
# Unit test for find-installed-quadlet (src/server/opt/podshift/fn/quadlet/find-installed-quadlet.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/find-installed-quadlet.sh"
    Q="${BATS_TEST_TMPDIR}/systemd"
    mkdir -p "${Q}/shop/deep"
}

@test "a file at the top is found" {
    : > "${Q}/web.container"
    run find-installed-quadlet web.container "${Q}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${Q}/web.container" ]
}

@test "a file in an app folder is found, matches are sorted" {
    : > "${Q}/web.container"
    : > "${Q}/shop/web.container"
    run find-installed-quadlet web.container "${Q}/"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${Q}/shop/web.container"$'\n'"${Q}/web.container" ]
}

@test "deeper files and other names are not found" {
    : > "${Q}/shop/deep/db.volume"
    : > "${Q}/db.volume.bak"
    run find-installed-quadlet db.volume "${Q}"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "an empty name, a path or a missing directory returns 1" {
    run find-installed-quadlet "" "${Q}"
    [ "${status}" -eq 1 ]
    run find-installed-quadlet shop/web.container "${Q}"
    [ "${status}" -eq 1 ]
    run find-installed-quadlet web.container "${Q}/nope"
    [ "${status}" -eq 1 ]
}
