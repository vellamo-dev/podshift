#!/usr/bin/env bats
# Unit test for cockpit-services-view-result (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-view-result.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-view-result.sh"
}

@test "found: the text is kept as is, trailing newline included" {
    run cockpit-services-view-result a.service unit yes 131072 <<< $'[Unit]\nDescription=A'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '. == {"unit":"a.service","mode":"unit","found":true,"text":"[Unit]\nDescription=A\n"}'
}

@test "not found: no text and stdin is not read" {
    run cockpit-services-view-result a.service status no 131072 < /dev/null
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"a.service","mode":"status","found":false}' ]
}

@test "too large: tooLarge and the text size instead of the text" {
    run cockpit-services-view-result a.service status yes 80 <<< "$(printf 'x%.0s' {1..100})"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"a.service","mode":"status","found":true,"tooLarge":true,"size":101}' ]
}

@test "missing arguments or a bad limit are refused" {
    run cockpit-services-view-result "" unit yes 10 < /dev/null
    [ "${status}" -eq 1 ]
    run cockpit-services-view-result a.service unit yes ten < /dev/null
    [ "${status}" -eq 1 ]
}
