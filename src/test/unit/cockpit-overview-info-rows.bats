#!/usr/bin/env bats
# Unit test for cockpit-overview-info-rows (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-info-rows.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-info-rows.sh"
}

@test "ids and labels are fixed and in order" {
    run cockpit-overview-info-rows '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.rows[].id] == ["os","podman","podshift","fail2ban"]
        and [.rows[].label] == ["OS","Podman","PodShift","Fail2Ban"]
        and all(.rows[]; .value == null)
        and all(.rows[]; .id | test("^[a-z0-9_]+$"))
    '
}

@test "provided values are used and missing keys stay null" {
    run cockpit-overview-info-rows '{"os":"Fedora Linux 45","podman":"5.0.0","fail2ban":null}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .rows[0].value == "Fedora Linux 45"
        and .rows[1].value == "5.0.0"
        and .rows[2].value == null
        and .rows[3].value == null
    '
}

@test "a non-object values argument fails" {
    run cockpit-overview-info-rows 'null'
    [ "${status}" -ne 0 ]
}
