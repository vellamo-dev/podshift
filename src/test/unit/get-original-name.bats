#!/usr/bin/env bats
# Unit test for get-original-name (src/server/opt/podshift/fn/quadlet/get-original-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/get-original-name.sh"
}

# A name without a suffix is returned unchanged.
@test "a plain name is printed as it is" {
    run get-original-name "web.container"
    [ "${status}" -eq 0 ]
    [ "${output}" = "web.container" ]
}

# Strips the all-digit collision suffix from a file name.
@test "the collision suffix of a file is removed" {
    run get-original-name "web.container.1761612345123456789"
    [ "${status}" -eq 0 ]
    [ "${output}" = "web.container" ]
}

# Strips the collision suffix from a bundle folder name.
@test "the collision suffix of a bundle folder is removed" {
    run get-original-name "app.qdl-bundle.1761612345123456789"
    [ "${output}" = "app.qdl-bundle" ]
}

# Uses the basename, ignoring the path.
@test "a path gives the name of its last part" {
    run get-original-name "/home/podshift/.quadlets/source/db.volume.1761612345123456789"
    [ "${output}" = "db.volume" ]
}

# Only one trailing digit suffix is stripped; earlier ones are kept.
@test "only one trailing suffix is removed" {
    run get-original-name "web.container.1.2"
    [ "${output}" = "web.container.1" ]
}

# Digits inside the name are not mistaken for a suffix.
@test "digits inside the name are kept" {
    run get-original-name "web2.container"
    [ "${output}" = "web2.container" ]
}

# A non-numeric suffix is kept (not a collision suffix).
@test "a suffix that is not all digits is kept" {
    run get-original-name "web.container.12ab"
    [ "${output}" = "web.container.12ab" ]
}
