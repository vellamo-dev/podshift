#!/usr/bin/env bats
# Unit test for cockpit-quadlet-drop-result (src/server/opt/podshift/cockpit/api/fn/drop/cockpit-quadlet-drop-result.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/drop/cockpit-quadlet-drop-result.sh"
}

@test "no problem is ok true" {
    run cockpit-quadlet-drop-result web.container
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"name":"web.container","ok":true}' ]
}

@test "a problem line gives the code and the message" {
    run cockpit-quadlet-drop-result shop.zip $'TOO_LARGE\tThe file is larger than 50 KB.'
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"name":"shop.zip","ok":false,"error":"TOO_LARGE","message":"The file is larger than 50 KB."}' ]
}

@test "a problem without a tab is the code with an empty message" {
    run cockpit-quadlet-drop-result web.container NAME_BUSY
    [ "${output}" = '{"name":"web.container","ok":false,"error":"NAME_BUSY","message":""}' ]
}

@test "special characters in the name are escaped" {
    run cockpit-quadlet-drop-result $'a"\x01.container' $'INVALID_NAME\tbad'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.name == "a\"\u0001.container" and .ok == false'
}
