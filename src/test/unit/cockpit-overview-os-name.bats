#!/usr/bin/env bats
# Unit test for cockpit-overview-os-name (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-os-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-os-name.sh"
}

@test "pretty name is used" {
    run cockpit-overview-os-name $'NAME="Fedora Linux"\nVERSION_ID=45\nPRETTY_NAME="Fedora Linux 45"\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Fedora Linux 45" ]
}

@test "name and version are used when pretty name is missing" {
    run cockpit-overview-os-name $'NAME="Fedora Linux"\nVERSION_ID=45\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Fedora Linux 45" ]
}

@test "empty text returns 1" {
    run cockpit-overview-os-name ""
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "unquoted pretty name is accepted" {
    run cockpit-overview-os-name $'PRETTY_NAME=Fedora\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Fedora" ]
}
