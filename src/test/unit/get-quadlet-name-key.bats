#!/usr/bin/env bats
# Unit test for get-quadlet-name-key (src/server/opt/podshift/fn/quadlet/get-quadlet-name-key.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/get-quadlet-name-key.sh"
}

@test "the four named types print their section and key" {
    run get-quadlet-name-key container
    [ "${output}" = "Container ContainerName" ]
    run get-quadlet-name-key network
    [ "${output}" = "Network NetworkName" ]
    run get-quadlet-name-key volume
    [ "${output}" = "Volume VolumeName" ]
    run get-quadlet-name-key pod
    [ "${status}" -eq 0 ]
    [ "${output}" = "Pod PodName" ]
}

@test "a type without a name key returns 1 and prints nothing" {
    run get-quadlet-name-key image
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    run get-quadlet-name-key ""
    [ "${status}" -eq 1 ]
}
