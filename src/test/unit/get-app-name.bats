#!/usr/bin/env bats
# Unit test for get-app-name (src/server/opt/podshift/fn/quadlet/get-app-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/get-app-name.sh"
}

# Strips the bundle marker to get the app name.
@test "the .qdl-bundle ending is removed" {
    run get-app-name "app.qdl-bundle"
    [ "${status}" -eq 0 ]
    [ "${output}" = "app" ]
}

# Strips both the collision suffix and the bundle marker.
@test "the collision suffix and the .qdl-bundle ending are removed" {
    run get-app-name "app.qdl-bundle.1761612345123456789"
    [ "${output}" = "app" ]
}

# Uses the basename, ignoring the path.
@test "a path gives the name of its last part" {
    run get-app-name "/home/podshift/.quadlets/source/my.app.qdl-bundle.1761612345123456789"
    [ "${output}" = "my.app" ]
}

# Only the collision suffix is stripped; digits in the zip name survive.
@test "digits at the end of the zip name are kept" {
    run get-app-name "app.2.qdl-bundle"
    [ "${output}" = "app.2" ]
    run get-app-name "app.2.qdl-bundle.1761612345123456789"
    [ "${output}" = "app.2" ]
}

# A bare name is returned unchanged.
@test "a name without the ending is printed as it is" {
    run get-app-name "app"
    [ "${output}" = "app" ]
}
