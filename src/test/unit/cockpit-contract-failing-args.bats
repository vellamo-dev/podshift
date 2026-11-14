#!/usr/bin/env bats
# Unit test for cockpit-contract-failing-args (src/server/opt/podshift/cockpit/api/fn/cockpit-contract-failing-args.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/cockpit-contract-failing-args.sh"
    CONTRACT="$(jq -c '.input' "${TST_PODSHIFT_DIR}/cockpit/api/modules/inspect/capability.json")"
}

@test "a bad kind or ref is named" {
    run cockpit-contract-failing-args "${CONTRACT}" '{"kind":"pod","ref":"db"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = "kind" ]
    run cockpit-contract-failing-args "${CONTRACT}" '{"kind":"volume","ref":"-rm"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = "ref" ]
}

@test "missing required arguments are named, sorted" {
    run cockpit-contract-failing-args "${CONTRACT}" '{}'
    [ "${status}" -eq 0 ]
    [ "${output}" = "kind, ref" ]
}

@test "an unknown argument and a bad mode are named, values are not printed" {
    run cockpit-contract-failing-args "${CONTRACT}" '{"kind":"volume","ref":"a","token":"s3cret"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = "token" ]
    run cockpit-contract-failing-args "${CONTRACT}" '{"kind":"volume","ref":"a","mode":"zip"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = "mode" ]
}

@test "an argument name that is not plain text is not echoed" {
    run cockpit-contract-failing-args "${CONTRACT}" '{"kind":"volume","ref":"a","<b>x</b>":1}'
    [ "${status}" -eq 1 ]
    [ "${output}" = "" ]
}

@test "matching arguments name nothing" {
    run cockpit-contract-failing-args "${CONTRACT}" '{"kind":"volume","ref":"a","mode":"file"}'
    [ "${status}" -eq 1 ]
    run cockpit-contract-failing-args '{"type":"object","properties":{},"additionalProperties":false}' '{}'
    [ "${status}" -eq 1 ]
}
