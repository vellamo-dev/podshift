#!/usr/bin/env bats
# Unit test for cockpit-overview-quadlet-unit (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-quadlet-unit.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-quadlet-unit.sh"
}

@test "container becomes a service" {
    run cockpit-overview-quadlet-unit app.container
    [ "${status}" -eq 0 ]
    [ "${output}" = "app.service" ]
}

@test "kube becomes a service" {
    run cockpit-overview-quadlet-unit web.kube
    [ "${status}" -eq 0 ]
    [ "${output}" = "web.service" ]
}

@test "pod, volume, network, image and build use a suffix" {
    run cockpit-overview-quadlet-unit db.pod
    [ "${output}" = "db-pod.service" ]
    run cockpit-overview-quadlet-unit db.volume
    [ "${output}" = "db-volume.service" ]
    run cockpit-overview-quadlet-unit lan.network
    [ "${output}" = "lan-network.service" ]
    run cockpit-overview-quadlet-unit base.image
    [ "${output}" = "base-image.service" ]
    run cockpit-overview-quadlet-unit app.build
    [ "${output}" = "app-build.service" ]
}

@test "a path is stripped" {
    run cockpit-overview-quadlet-unit /home/podshift/.config/containers/systemd/app.container
    [ "${status}" -eq 0 ]
    [ "${output}" = "app.service" ]
}

@test "an unknown suffix returns 1" {
    run cockpit-overview-quadlet-unit notes.txt
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
