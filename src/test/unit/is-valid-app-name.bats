#!/usr/bin/env bats
# Unit test for is-valid-app-name (src/server/opt/podshift/fn/quadlet/is-valid-app-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/is-valid-app-name.sh"
}

# Alphanumeric start plus allowed chars is valid.
@test "good names return 0 and print nothing" {
    for name in app web2 My_App my-app 1app a my.app app.v2 a.b.c app_1.2-3 9; do
        run is-valid-app-name "${name}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

# Empty or missing name is invalid.
@test "an empty name or no argument returns 1" {
    run is-valid-app-name ""
    [ "${status}" -eq 1 ]
    run is-valid-app-name
    [ "${status}" -eq 1 ]
}

# The first char must be alphanumeric.
@test "a leading dot, dash or underscore returns 1" {
    for name in .app -app _app .hidden ..; do
        run is-valid-app-name "${name}"
        [ "${status}" -eq 1 ]
        [ -z "${output}" ]
    done
}

# The charset is limited to letters, digits, underscore, dot and dash.
@test "characters other than letters, digits, underscore, dot and dash return 1" {
    for name in "my app" "my/app" 'my\app' "app!" "app@" "app:1" "app,1" "app;rm" 'app$x' 'app`x`' "app'" 'app"' "app*" "app~" "appé" "приложение" "app+1" "app=1" "app%"; do
        run is-valid-app-name "${name}"
        [ "${status}" -eq 1 ]
        [ -z "${output}" ]
    done
}

# Control chars are rejected.
@test "a newline or a tab in the name returns 1" {
    run is-valid-app-name $'app\n'
    [ "${status}" -eq 1 ]
    run is-valid-app-name $'app\nx'
    [ "${status}" -eq 1 ]
    run is-valid-app-name $'app\tx'
    [ "${status}" -eq 1 ]
}

# A quadlet extension suffix is rejected.
@test "a name that ends like a quadlet file returns 1" {
    for ext in artifact build container image kube network pod volume quadlets; do
        run is-valid-app-name "app.${ext}"
        [ "${status}" -eq 1 ]
        [ -z "${output}" ]
    done
}

# The .qdl-bundle and .zip endings are rejected.
@test "the bundle and zip endings return 1" {
    run is-valid-app-name "app.qdl-bundle"
    [ "${status}" -eq 1 ]
    run is-valid-app-name "app.zip"
    [ "${status}" -eq 1 ]
}

# A reserved word is only rejected as the final extension.
@test "a reserved word inside the name or before another ending is fine" {
    for name in my.container.app container-app containerapp app.container2 app-pod app_volume my.pod.v2 build image app.zipx; do
        run is-valid-app-name "${name}"
        [ "${status}" -eq 0 ]
    done
}

# A bare reserved word without a dot is allowed.
@test "a name that is only a reserved word without a dot is fine" {
    for name in container pod volume network build image kube artifact quadlets zip; do
        run is-valid-app-name "${name}"
        [ "${status}" -eq 0 ]
    done
}

# The final extension decides, regardless of the rest.
@test "a dot name before a reserved ending is still reserved" {
    run is-valid-app-name ".container"
    [ "${status}" -eq 1 ]
    run is-valid-app-name "a.b.container"
    [ "${status}" -eq 1 ]
}
