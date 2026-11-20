#!/usr/bin/env bats
# Unit test for is-valid-env-tag (src/server/opt/podshift/fn/utils/is-valid-env-tag.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/is-valid-env-tag.sh"
}

@test "good tags return 0 and print nothing" {
    for tag in dev prod DEV test-1 stg.eu _x a 9 a.b_c-d "$(printf 'a%.0s' {1..128})"; do
        run is-valid-env-tag "${tag}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "bad tags return 1" {
    for tag in "" .dev -dev "a b" 'a"b' "a/b" "a:b" "Ä" $'dev\n' "$(printf 'a%.0s' {1..129})"; do
        run is-valid-env-tag "${tag}"
        [ "${status}" -eq 1 ]
    done
    run is-valid-env-tag
    [ "${status}" -eq 1 ]
}
