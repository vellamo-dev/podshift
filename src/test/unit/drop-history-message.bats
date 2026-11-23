#!/usr/bin/env bats
# Unit test for drop-history-message (src/server/opt/podshift/fn/quadlet/drop-history-message.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/drop-history-message.sh"
    ID="018bcfe5-6800-7012-b456-789abcdef012"
}

@test "id, name and status only" {
    run drop-history-message "${ID}" web.container accepted
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"web.container","status":"accepted"}' ]
}

@test "reason and description are added when set" {
    run drop-history-message "${ID}" shop.zip failed "missing [Container] section" "Shop API"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"shop.zip","status":"failed","reason":"missing [Container] section","description":"Shop API"}' ]
}

@test "every drop status is accepted" {
    local s
    for s in accepted validated installing installed unchanged failed refused; do
        run drop-history-message "${ID}" a.volume "${s}"
        [ "${status}" -eq 0 ]
    done
}

@test "uploaded, removing, removed and unknown statuses are refused" {
    local s
    for s in uploaded removing removed done; do
        run drop-history-message "${ID}" web.container "${s}"
        [ "${status}" -eq 1 ]
        [ -z "${output}" ]
    done
}

@test "an empty name or a missing or invalid ID is refused" {
    run drop-history-message "${ID}" "" accepted
    [ "${status}" -eq 1 ]
    run drop-history-message "" web.container accepted
    [ "${status}" -eq 1 ]
    run drop-history-message 018bcfe5-6800-4012-b456-789abcdef012 web.container accepted
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "quotes and newlines are escaped and long text is cut" {
    local long
    long="$(printf 'x%.0s' {1..300})"
    run drop-history-message "${ID}" 'a"b.container' refused $'line1\nline2' "${long}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.name == "a\"b.container" and .reason == "line1\nline2" and (.description | length) == 200'
}
