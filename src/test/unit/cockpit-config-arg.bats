#!/usr/bin/env bats
# Unit test for cockpit-config-arg (src/server/opt/podshift/cockpit/api/fn/config/cockpit-config-arg.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/config/cockpit-config-arg.sh"
}

@test "a string field is printed as it is" {
    run cockpit-config-arg '{"key":"TSV_APP","value":"a b \"c\" $HOME \\\\ x"}' value
    [ "${status}" -eq 0 ]
    [ "${output}" = 'a b "c" $HOME \\ x' ]
    run cockpit-config-arg '{"key":"TSV_APP","value":"x"}' key
    [ "${output}" = "TSV_APP" ]
}

@test "an empty string stays empty" {
    run cockpit-config-arg '{"value":""}' value
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "a value with a control character is printed as one \\x01" {
    for json in '{"value":"a\n"}' '{"value":"a\nb"}' '{"value":"\t"}' '{"value":"a\u0000b"}' '{"value":"a\u007f"}' '{"value":"a\u001b"}'; do
        run cockpit-config-arg "${json}" value
        [ "${status}" -eq 0 ]
        [ "${output}" = $'\x01' ]
    done
}

@test "a missing or non-string field fails" {
    run cockpit-config-arg '{"key":"TSV_APP"}' value
    [ "${status}" -ne 0 ]
    run cockpit-config-arg '{"value":1}' value
    [ "${status}" -ne 0 ]
    run cockpit-config-arg 'not json' value
    [ "${status}" -ne 0 ]
}
