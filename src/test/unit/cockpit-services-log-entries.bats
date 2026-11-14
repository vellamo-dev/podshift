#!/usr/bin/env bats
# Unit test for cockpit-services-log-entries (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-log-entries.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-log-entries.sh"
    JOURNAL="${BATS_TEST_DIRNAME}/fixtures/cockpit-services/journal.json"
}

@test "entries keep time, hostname, identifier, pid, priority and message; other lines are skipped" {
    run cockpit-services-log-entries example-app.service < "${JOURNAL}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .unit == "example-app.service" and .found == true and .readable == true
        and (.entries | length) == 5
        and .entries[1] == {"time":"2026-11-12T09:02:13Z","hostname":"podshift","identifier":"example-app","priority":3,
            "message":"Error: initializing source docker://registry.example.invalid/example-app:latest: no such host","pid":3877}
    '
}

@test "fallbacks: _COMM, byte-array message, missing or bad priority, SYSLOG_PID, null message" {
    run cockpit-services-log-entries example-app.service < "${JOURNAL}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .entries[3] == {"time":"2026-11-12T09:02:14Z","hostname":"podshift","identifier":"conmon","priority":6,"message":"hello"}
        and .entries[4] == {"time":"2026-11-12T09:02:14Z","hostname":"podshift","identifier":"unknown","priority":6,"message":"","pid":77}
    '
}

@test "at most the given number of the newest entries, oldest first" {
    run cockpit-services-log-entries example-app.service 2 < "${JOURNAL}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '[.entries[].identifier] == ["conmon","unknown"]'
    run bash -c 'source "$1"; for i in $(seq 1 150); do printf "{\"__REALTIME_TIMESTAMP\":\"%s000000\",\"MESSAGE\":\"line %s\"}\n" "$((1794474000 + i))" "${i}"; done | cockpit-services-log-entries a.service' _ "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-log-entries.sh"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '(.entries | length) == 100 and .entries[0].message == "line 51" and .entries[99].message == "line 150"'
}

@test "a long message is cut to 1024 characters plus an ellipsis" {
    run bash -c 'source "$1"; jq -n -c "{__REALTIME_TIMESTAMP: \"1794474000000000\", MESSAGE: (\"a\" * 5000)}" | cockpit-services-log-entries a.service' _ "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-log-entries.sh"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '(.entries[0].message | length) == 1025 and (.entries[0].message | endswith("…"))'
}

@test "an empty journal gives no entries; a missing unit or a bad count is refused" {
    run cockpit-services-log-entries a.service < /dev/null
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"a.service","found":true,"readable":true,"entries":[]}' ]
    run cockpit-services-log-entries "" < /dev/null
    [ "${status}" -eq 1 ]
    run cockpit-services-log-entries a.service 0 < /dev/null
    [ "${status}" -eq 1 ]
}

@test "-- No entries -- alone gives an empty list" {
    run cockpit-services-log-entries a.service <<< '-- No entries --'
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"a.service","found":true,"readable":true,"entries":[]}' ]
}
