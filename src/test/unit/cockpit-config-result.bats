#!/usr/bin/env bats
# Unit test for cockpit-config-result (src/server/opt/podshift/cockpit/api/fn/config/cockpit-config-result.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/config/cockpit-config-result.sh"
}

@test "no problem is ok true" {
    run cockpit-config-result TSV_APP
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"key":"TSV_APP","ok":true}' ]
}

@test "a problem line gives the code and the message" {
    run cockpit-config-result TSV_DB_PASSWORD $'SENSITIVE_NAME\tSecrets don\'t belong in config. Use a Podman secret instead.'
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"key":"TSV_DB_PASSWORD","ok":false,"error":"SENSITIVE_NAME","message":"Secrets don'"'"'t belong in config. Use a Podman secret instead."}' ]
}

@test "a problem without a tab is the code with an empty message" {
    run cockpit-config-result TSV_ENV ALREADY_SET
    [ "${output}" = '{"key":"TSV_ENV","ok":false,"error":"ALREADY_SET","message":""}' ]
}

@test "special characters in the key and message are escaped" {
    run cockpit-config-result $'TSV_\x01"' $'INVALID_NAME\tbad "name"'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.key == "TSV_\u0001\"" and .message == "bad \"name\"" and .ok == false'
}
