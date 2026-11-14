#!/usr/bin/env bats
# Unit test for cockpit-networks-unit-networks (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-networks-unit-networks.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-networks-unit-networks.sh"
}

@test "the name after options and their values is found" {
    run cockpit-networks-unit-networks $'[Service]\nType=oneshot\nExecStart=/usr/bin/podman network create --ignore --subnet 10.202.0.0/24 --label podshift.example=1 example-unit\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "example-unit" ]
}

@test "prefixes, --opt=value forms and quotes are handled" {
    run cockpit-networks-unit-networks $'ExecStartPre=-/usr/bin/podman network create --driver=bridge -d bridge --internal "internal-db"\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "internal-db" ]
}

@test "several Exec lines give each name once, in order" {
    run cockpit-networks-unit-networks $'ExecStartPre=podman network create one\nExecStart=podman network create two\nExecStartPost=podman network create one\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = $'one\ntwo' ]
}

@test "other podman commands and non-Exec lines are ignored" {
    run cockpit-networks-unit-networks $'Description=podman network create fake\nExecStop=/usr/bin/podman network rm -f example-unit\nExecStart=/usr/bin/podman run --network example-unit img\n'
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "empty text prints nothing" {
    run cockpit-networks-unit-networks ""
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}
