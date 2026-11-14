#!/usr/bin/env bats
# Unit test for cockpit-services-journal-matches (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-journal-matches.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-journal-matches.sh"
}

@test "three match groups for the unit and the UID, joined with +" {
    run cockpit-services-journal-matches web.service 300
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%s\n' _SYSTEMD_USER_UNIT=web.service _UID=300 + USER_UNIT=web.service _UID=300 + OBJECT_SYSTEMD_USER_UNIT=web.service _UID=300)" ]
}

@test "an escaped unit name is passed unchanged" {
    run cockpit-services-journal-matches 'app\x2dweb@1.service' 1001
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = '_SYSTEMD_USER_UNIT=app\x2dweb@1.service' ]
    [ "${lines[1]}" = '_UID=1001' ]
}

@test "an empty or spaced unit, or a UID that is not a number, is refused" {
    run cockpit-services-journal-matches "" 300
    [ "${status}" -eq 1 ]
    run cockpit-services-journal-matches "a b.service" 300
    [ "${status}" -eq 1 ]
    run cockpit-services-journal-matches web.service podshift
    [ "${status}" -eq 1 ]
    run cockpit-services-journal-matches web.service ""
    [ "${status}" -eq 1 ]
}
