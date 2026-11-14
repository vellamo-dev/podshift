#!/usr/bin/env bats
# Unit test for cockpit-overview-usage-rows (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-usage-rows.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-usage-rows.sh"
}

@test "ids and labels are fixed and in order" {
    run cockpit-overview-usage-rows '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.rows[].id] == ["services","networks","containers","volumes","images","quadlets","secrets"]
        and [.rows[].label] == ["Services","Networks","Containers","Volumes","Images","Quadlets","Secrets"]
        and all(.rows[]; .value == null)
        and all(.rows[]; .id | test("^[a-z0-9_]+$"))
    '
}

@test "provided values are used and missing keys stay null" {
    run cockpit-overview-usage-rows '{"services":"1 / 2","networks":"1","containers":"2 / 4","volumes":"0 / 1","images":"2 / 5","quadlets":"0","secrets":"0"}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .rows[0].value == "1 / 2"
        and .rows[1].value == "1"
        and .rows[2].value == "2 / 4"
        and .rows[3].value == "0 / 1"
        and .rows[4].value == "2 / 5"
        and .rows[5].value == "0"
        and .rows[6].value == "0"
    '
}

@test "a non-object values argument fails" {
    run cockpit-overview-usage-rows '"x"'
    [ "${status}" -ne 0 ]
}
