#!/usr/bin/env bats
# Unit test for cockpit-services-loaded (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-loaded.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-loaded.sh"
}

@test "plain list-units text: loaded units with their active state, not-found, masked and error left out" {
    run cockpit-services-loaded $'dbus-broker.service loaded active running D-Bus User Message Bus\nfoo.service loaded failed failed Failed unit\nbar.service masked inactive dead Masked unit\nbaz.service error inactive dead Error unit\nqux.service not-found inactive dead Missing unit\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = $'dbus-broker.service\tactive\nfoo.service\tfailed' ]
}

@test "the header, the failed-unit marker and the legend are ignored" {
    run cockpit-services-loaded $'  UNIT LOAD ACTIVE SUB DESCRIPTION\n● app.service loaded failed failed App\n●other.service loaded active running Other\n\n2 loaded units listed.\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = $'app.service\tfailed\nother.service\tactive' ]
}

@test "non-service units are ignored and an empty list prints nothing" {
    run cockpit-services-loaded $'app.timer loaded active waiting Timer\n'
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    run cockpit-services-loaded ""
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "text can also be read from stdin" {
    run cockpit-services-loaded <<< 'app@one.service loaded activating start Instance'
    [ "${status}" -eq 0 ]
    [ "${output}" = $'app@one.service\tactivating' ]
}

@test "a marker glued to the name is dropped in the C and the UTF-8 locale alike" {
    local locale
    for locale in C C.UTF-8; do
        LC_ALL="${locale}" run cockpit-services-loaded $'●app.service loaded failed failed App\n'
        [ "${status}" -eq 0 ]
        [ "${output}" = $'app.service\tfailed' ]
    done
}
