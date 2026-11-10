#!/usr/bin/env bats
# Unit test for find-duplicate-units (src/server/opt/podshift/fn/quadlet/find-duplicate-units.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/find-duplicate-units.sh"
    Q="${BATS_TEST_TMPDIR}/quadlets"
    S="${BATS_TEST_TMPDIR}/staging"
    mkdir -p "${Q}" "${S}"
}

# Creates a file (and its folder) under the given base directory.
make-file() {
    mkdir -p "$(dirname "${1}")"
    : > "${1}"
}

# Nothing installed, nothing to report.
@test "an empty quadlets directory gives no duplicate" {
    make-file "${S}/web.container"
    run find-duplicate-units "${S}/web.container" "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

# A missing quadlets directory is not an error.
@test "a missing quadlets directory gives nothing and returns 0" {
    make-file "${S}/web.container"
    run find-duplicate-units "${S}/web.container" "${BATS_TEST_TMPDIR}/nope"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

# A single file replacing the same file at the top level is a replace.
@test "a single file replacing the same top-level file is not a duplicate" {
    make-file "${S}/web.container"
    make-file "${Q}/web.container"
    run find-duplicate-units "${S}/web.container" "${Q}"
    [ -z "${output}" ]
}

# The same name inside an application folder is another place.
@test "a single file named like a file of an application is a duplicate" {
    make-file "${S}/web.container"
    make-file "${Q}/shop/web.container"
    run find-duplicate-units "${S}/web.container" "${Q}"
    [ "${output}" = "${Q}/shop/web.container" ]
}

# A bundle replacing its own application is a replace.
@test "a bundle replacing the same application is not a duplicate" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${S}/shop.qdl-bundle/db.container"
    make-file "${Q}/shop/web.container"
    make-file "${Q}/shop/db.container"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}"
    [ -z "${output}" ]
}

# The collision suffix and a dotted name are handled by get-app-name.
@test "a bundle with a dotted name and a collision suffix finds its own application" {
    make-file "${S}/my.app.qdl-bundle.1761612345123456789/web.container"
    make-file "${Q}/my.app/web.container"
    run find-duplicate-units "${S}/my.app.qdl-bundle.1761612345123456789" "${Q}"
    [ -z "${output}" ]
}

# Another application has the same unit name.
@test "a bundle file named like a file of another application is a duplicate" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${Q}/blog/web.container"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}"
    [ "${output}" = "${Q}/blog/web.container" ]
}

# A single installed file has the same unit name as the bundle file.
@test "a bundle file named like a top-level single file is a duplicate" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${Q}/web.container"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}"
    [ "${output}" = "${Q}/web.container" ]
}

# Only the files that share a name are reported, in sorted order.
@test "every duplicate is listed once per installed file, other names are ignored" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${S}/shop.qdl-bundle/net.network"
    make-file "${S}/shop.qdl-bundle/db.container"
    make-file "${Q}/blog/web.container"
    make-file "${Q}/blog/net.network"
    make-file "${Q}/blog/other.container"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}"
    [ "${output}" = "${Q}/blog/net.network"$'\n'"${Q}/blog/web.container" ]
}

# A file that is not a unit file does not make a unit.
@test "a file without a Quadlet extension is ignored" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${S}/shop.qdl-bundle/app.env"
    make-file "${Q}/blog/app.env"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}"
    [ -z "${output}" ]
}

# A trailing slash on the quadlets directory changes nothing.
@test "a trailing slash on the quadlets directory is accepted" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${Q}/shop/web.container"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}/"
    [ -z "${output}" ]
}

# A name that only ends alike is a different unit.
@test "a name that only ends the same is not a duplicate" {
    make-file "${S}/shop.qdl-bundle/web.container"
    make-file "${Q}/blog/myweb.container"
    run find-duplicate-units "${S}/shop.qdl-bundle" "${Q}"
    [ -z "${output}" ]
}
