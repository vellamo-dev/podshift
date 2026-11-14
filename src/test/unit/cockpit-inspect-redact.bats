#!/usr/bin/env bats
# Unit test for cockpit-inspect-redact (src/server/opt/podshift/cockpit/api/fn/inspect/cockpit-inspect-redact.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/inspect/cockpit-inspect-redact.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-inspect"
}

@test "SecretData is removed from every secret object, at any depth" {
    run cockpit-inspect-redact secret '[{"ID":"a","SecretData":"must-never-leak","Spec":{"Name":"x","SecretData":"must-never-leak"}},{"ID":"b","SecretData":""}]'
    [ "${status}" -eq 0 ]
    [ "${output}" = '[{"ID":"a","Spec":{"Name":"x"}},{"ID":"b"}]' ]
    [[ "${output}" != *must-never-leak* ]]
}

@test "a secret without SecretData is unchanged" {
    run cockpit-inspect-redact secret "$(cat "${FIX}/secret.json")"
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(jq -c . "${FIX}/secret.json")" ]
}

@test "other kinds are passed on unchanged" {
    local kind
    for kind in container image volume network; do
        run cockpit-inspect-redact "${kind}" "$(cat "${FIX}/${kind}.json")"
        [ "${status}" -eq 0 ]
        [ "${output}" = "$(jq -c . "${FIX}/${kind}.json")" ]
    done
}

@test "an empty array stays empty" {
    run cockpit-inspect-redact secret '[]'
    [ "${status}" -eq 0 ]
    [ "${output}" = '[]' ]
}

@test "input that is not a JSON array, or an empty kind, returns 1" {
    run cockpit-inspect-redact secret '{"SecretData":"x"}'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-redact secret 'not json'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-redact secret ''
    [ "${status}" -eq 1 ]
    run cockpit-inspect-redact '' '[]'
    [ "${status}" -eq 1 ]
}
