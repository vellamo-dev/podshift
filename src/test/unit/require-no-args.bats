#!/usr/bin/env bats
# Unit test for require-no-args (src/server/opt/podshift/fn/utils/require-no-args.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/require-no-args.sh"
}

@test "only the name: no output and exit 0" {
    run require-no-args update
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "any argument, even an empty one or --help, is refused with the help hint" {
    local arg
    for arg in --help -h x ""; do
        run require-no-args update "${arg}"
        [ "${status}" -eq 1 ]
        [ "${output}" = "update takes no arguments. See 'podshift --help update'." ]
    done
    run require-no-args status-user a b
    [ "${status}" -eq 1 ]
    [ "${output}" = "status-user takes no arguments. See 'podshift --help status-user'." ]
}
