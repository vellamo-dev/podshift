#!/usr/bin/env bats
# Unit test for cockpit-drop-history-items (src/server/opt/podshift/cockpit/api/fn/drop/cockpit-drop-history-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/drop/cockpit-drop-history-items.sh"
    A="018bcfe5-6800-7000-8000-00000000000a"
    B="018bcfe5-6800-7000-8000-00000000000b"
    C="018bcfe5-6800-7000-8000-00000000000c"
}

# rec <seconds> <message json>: one journalctl -o json line of the history tag.
rec() {
    jq -n -c --arg t "${1}000000" --arg m "${2}" '{__REALTIME_TIMESTAMP: $t, SYSLOG_IDENTIFIER: "podshift-drop-history", MESSAGE: $m}'
}

# msg <id> <name> <status> [reason] [description]: one drop history message.
msg() {
    jq -n -c --arg id "${1}" --arg n "${2}" --arg s "${3}" --arg r "${4-}" --arg d "${5-}" \
        '{id: $id, name: $n, status: $s} + (if $r == "" then {} else {reason: $r} end) + (if $d == "" then {} else {description: $d} end)'
}

@test "no input gives an empty list" {
    run cockpit-drop-history-items < /dev/null
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"readable":true,"items":[]}' ]
}

@test "the newest record of each drop wins, newest item first" {
    local input
    input="$(
        rec 1700000000 "$(msg "${A}" web.container accepted "" Web)"
        rec 1700000010 "$(msg "${B}" shop.zip accepted)"
        rec 1700000020 "$(msg "${A}" web.container installed)"
        rec 1700000030 "$(msg "${B}" shop.zip failed "bad line 3")"
    )"
    run cockpit-drop-history-items <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"readable":true,"items":[{"id":"018bcfe5-6800-7000-8000-00000000000b","name":"shop.zip","status":"failed","time":"2023-11-14T22:13:50Z","reason":"bad line 3"},{"id":"018bcfe5-6800-7000-8000-00000000000a","name":"web.container","status":"installed","time":"2023-11-14T22:13:40Z","description":"Web"}]}' ]
}

@test "the same name dropped twice gives two items" {
    local input
    input="$(
        rec 1700000000 "$(msg "${A}" web.container installed)"
        rec 1700000010 "$(msg "${B}" web.container unchanged)"
        rec 1700000020 "$(msg "${C}" web.container unchanged)"
    )"
    run cockpit-drop-history-items <<< "${input}"
    printf '%s' "${output}" | jq -e '[.items[] | .id[-1:] + " " + .status] == ["c unchanged", "b unchanged", "a installed"]'
}

@test "a reason of an older record is not kept" {
    local input
    input="$(
        rec 1700000000 "$(msg "${A}" web.container failed old)"
        rec 1700000005 "$(msg "${A}" web.container installed)"
    )"
    run cockpit-drop-history-items <<< "${input}"
    printf '%s' "${output}" | jq -e '.items == [{"id":"018bcfe5-6800-7000-8000-00000000000a","name":"web.container","status":"installed","time":"2023-11-14T22:13:25Z"}]'
}

@test "other tags, bad messages, records without an ID and old statuses are skipped" {
    local input
    input="$(
        printf '%s\n' '-- No entries --'
        jq -n -c --arg m "$(msg "${A}" x.container accepted)" '{__REALTIME_TIMESTAMP: "1700000000000000", SYSLOG_IDENTIFIER: "podshift-drop-process", MESSAGE: $m}'
        rec 1700000001 'not json'
        rec 1700000002 "$(msg "${A}" y.container done)"
        rec 1700000003 '{"id":"018bcfe5-6800-7000-8000-00000000000a","status":"accepted"}'
        rec 1700000004 '{"name":"old.container","status":"installed"}'
        rec 1700000005 "$(msg 018bcfe5-6800-4000-8000-00000000000a v4.container installed)"
        rec 1700000006 "$(msg "${B}" up.container uploaded)"
        rec 1700000007 "$(msg "${B}" rm.container removing)"
        rec 1700000008 "$(msg "${B}" rm.container removed)"
        jq -n -c '{__REALTIME_TIMESTAMP: "1700000009000000", SYSLOG_IDENTIFIER: "podshift-drop-history", MESSAGE: [123, 125]}'
        rec 1700000010 "$(msg "${C}" ok.volume refused "hidden file")"
    )"
    run cockpit-drop-history-items <<< "${input}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items | length == 1 and .[0].name == "ok.volume"'
}

@test "the count keeps only the newest items" {
    local input
    input="$(
        rec 1700000001 "$(msg "${A}" a.container installed)"
        rec 1700000002 "$(msg "${B}" b.container installed)"
        rec 1700000003 "$(msg "${C}" c.container installed)"
    )"
    run cockpit-drop-history-items 2 <<< "${input}"
    printf '%s' "${output}" | jq -e '[.items[].name] == ["c.container","b.container"]'
    run cockpit-drop-history-items 0 <<< "${input}"
    [ "${status}" -eq 1 ]
    run cockpit-drop-history-items x <<< "${input}"
    [ "${status}" -eq 1 ]
}

@test "records in the same second keep the journal order" {
    local input
    input="$(
        rec 1700000000 "$(msg "${A}" web.container installing)"
        rec 1700000000 "$(msg "${A}" web.container installed)"
    )"
    run cockpit-drop-history-items <<< "${input}"
    printf '%s' "${output}" | jq -e '.items[0].status == "installed"'
}

@test "the unchanged status is kept" {
    local input
    input="$(
        rec 1700000001 "$(msg "${A}" a.container unchanged)"
    )"
    run cockpit-drop-history-items <<< "${input}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '[.items[].status] == ["unchanged"]'
}
