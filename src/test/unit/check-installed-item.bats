#!/usr/bin/env bats
# Unit test for check-installed-item (src/server/opt/podshift/fn/quadlet/check-installed-item.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/check-installed-item.sh"
    Q="${BATS_TEST_TMPDIR}/systemd"
    S="${BATS_TEST_TMPDIR}/source"
    mkdir -p "${Q}" "${S}"
}

@test "a file that is not installed is new" {
    printf 'a\n' > "${S}/web.container"
    run check-installed-item "${S}/web.container" "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "the same file at the top is unchanged, also with a collision suffix" {
    printf 'a\n' > "${S}/web.container.1761612345123456789"
    printf 'a\n' > "${Q}/web.container"
    run check-installed-item "${S}/web.container.1761612345123456789" "${Q}"
    [ "${status}" -eq 2 ]
    [ -z "${output}" ]
}

@test "a different file at the top is refused" {
    printf 'a\n' > "${S}/web.container"
    printf 'b\n' > "${Q}/web.container"
    run check-installed-item "${S}/web.container" "${Q}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container is already installed, remove it first" ]
}

@test "a file installed in an app folder is refused, even with the same content" {
    mkdir -p "${Q}/shop"
    printf 'a\n' > "${S}/web.container"
    printf 'a\n' > "${Q}/shop/web.container"
    run check-installed-item "${S}/web.container" "${Q}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container is already installed in app shop, remove it first" ]
}

@test "a bundle that is not installed is new" {
    mkdir -p "${S}/b"
    printf 'a\n' > "${S}/b/web.container"
    run check-installed-item "${S}/b" "${Q}" shop
    [ "${status}" -eq 0 ]
}

@test "the same bundle is unchanged" {
    mkdir -p "${S}/b" "${Q}/shop"
    printf 'a\n' > "${S}/b/web.container"
    printf 'n\n' > "${S}/b/web.network"
    cp "${S}/b/web.container" "${S}/b/web.network" "${Q}/shop/"
    run check-installed-item "${S}/b" "${Q}" shop
    [ "${status}" -eq 2 ]
}

@test "an app with other files or other content is refused" {
    mkdir -p "${S}/b" "${Q}/shop"
    printf 'a\n' > "${S}/b/web.container"
    printf 'b\n' > "${Q}/shop/web.container"
    run check-installed-item "${S}/b" "${Q}" shop
    [ "${status}" -eq 1 ]
    [ "${output}" = "app shop is already installed, remove it first" ]
    printf 'a\n' > "${Q}/shop/web.container"
    printf 'n\n' > "${Q}/shop/web.network"
    run check-installed-item "${S}/b" "${Q}" shop
    [ "${status}" -eq 1 ]
    [ "${output}" = "app shop is already installed, remove it first" ]
}

@test "a bundle file installed elsewhere is refused" {
    mkdir -p "${S}/b" "${Q}/blog"
    printf 'a\n' > "${S}/b/web.container"
    printf 'a\n' > "${Q}/blog/web.container"
    run check-installed-item "${S}/b" "${Q}" shop
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container is already installed (blog/web.container), remove it first" ]
}

@test "a folder without an app name returns 1" {
    mkdir -p "${S}/b"
    run check-installed-item "${S}/b" "${Q}"
    [ "${status}" -eq 1 ]
}
