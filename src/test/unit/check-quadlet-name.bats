#!/usr/bin/env bats
# Unit test for check-quadlet-name (src/server/opt/podshift/fn/quadlet/check-quadlet-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/check-quadlet-name.sh"
    D="${BATS_TEST_TMPDIR}"
}

@test "a container with ContainerName equal to the base name passes" {
    printf '[Container]\nContainerName=web\nImage=x\n' > "${D}/web.container"
    run check-quadlet-name "${D}/web.container"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "the collision suffix is ignored" {
    printf '[Network]\nNetworkName=front\n' > "${D}/front.network.1761612345123456789"
    run check-quadlet-name "${D}/front.network.1761612345123456789"
    [ "${status}" -eq 0 ]
}

@test "a missing name key is refused" {
    printf '[Volume]\nLabel=a=b\n' > "${D}/data.volume"
    run check-quadlet-name "${D}/data.volume"
    [ "${status}" -eq 1 ]
    [ "${output}" = "data.volume: [Volume] missing VolumeName" ]
}

@test "a name key in another section does not count" {
    printf '[Unit]\nPodName=web\n[Pod]\n' > "${D}/web.pod"
    run check-quadlet-name "${D}/web.pod"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.pod: [Pod] missing PodName" ]
}

@test "a name key that differs from the base name is refused" {
    printf '[Container]\nContainerName=other\n' > "${D}/web.container"
    run check-quadlet-name "${D}/web.container"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container: ContainerName must be web, not other" ]
}

@test "the reserved endings are refused for any type" {
    local ending
    for ending in pod network volume image build; do
        printf '[Container]\nContainerName=web-%s\n' "${ending}" > "${D}/web-${ending}.container"
        run check-quadlet-name "${D}/web-${ending}.container"
        [ "${status}" -eq 1 ]
        [ "${output}" = "web-${ending}.container: the name must not end with -${ending}" ]
    done
    printf '[Image]\nImage=x\n' > "${D}/base-network.image"
    run check-quadlet-name "${D}/base-network.image"
    [ "${status}" -eq 1 ]
}

@test "a -container ending and an image without a name key pass" {
    printf '[Container]\nContainerName=example-volume-container\n' > "${D}/example-volume-container.container"
    run check-quadlet-name "${D}/example-volume-container.container"
    [ "${status}" -eq 0 ]
    printf '[Image]\nImage=docker.io/library/alpine:latest\n' > "${D}/alpine.image"
    run check-quadlet-name "${D}/alpine.image"
    [ "${status}" -eq 0 ]
}
