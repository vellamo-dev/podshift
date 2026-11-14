#!/usr/bin/env bats
# Unit test for cockpit-services-args (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-args.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-args.sh"
}

@test "service-view: unit and mode are printed" {
    run cockpit-services-args '{"unit":"example-app.service","mode":"status"}' yes
    [ "${status}" -eq 0 ]
    [ "${output}" = $'example-app.service\tstatus' ]
    run cockpit-services-args '{"unit":"app@one.service","mode":"unit"}' yes
    [ "${status}" -eq 0 ]
    [ "${output}" = $'app@one.service\tunit' ]
}

@test "a systemd escape is accepted" {
    run cockpit-services-args '{"unit":"foo\\x2dbar.service","mode":"unit"}' yes
    [ "${status}" -eq 0 ]
    [ "${output}" = $'foo\\x2dbar.service\tunit' ]
}

@test "service-logs: unit only" {
    run cockpit-services-args '{"unit":"example-app.service"}' no
    [ "${status}" -eq 0 ]
    [ "${output}" = $'example-app.service\t' ]
}

@test "bad unit names are refused" {
    local unit
    for unit in "" "-a.service" ".a.service" "a.socket" "a b.service" "a/b.service" "a;b.service" 'a\x2.service' "a.service.bak"; do
        run cockpit-services-args "$(jq -n -c --arg u "${unit}" '{unit: $u, mode: "unit"}')" yes
        [ "${status}" -eq 1 ]
    done
    run cockpit-services-args "$(jq -n -c --arg u "$(printf 'a%.0s' {1..250}).service" '{unit: $u, mode: "unit"}')" yes
    [ "${status}" -eq 1 ]
}

@test "a missing, unknown or unexpected mode is refused" {
    run cockpit-services-args '{"unit":"a.service"}' yes
    [ "${status}" -eq 1 ]
    run cockpit-services-args '{"unit":"a.service","mode":"logs"}' yes
    [ "${status}" -eq 1 ]
    run cockpit-services-args '{"unit":"a.service","mode":"unit"}' no
    [ "${status}" -eq 1 ]
    run cockpit-services-args '{"unit":1}' no
    [ "${status}" -eq 1 ]
    run cockpit-services-args 'not json' no
    [ "${status}" -eq 1 ]
}
