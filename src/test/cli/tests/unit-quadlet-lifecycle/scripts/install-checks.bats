#!/usr/bin/env bats
# Stubbed tests for check-quadlet-names-free and check-quadlet-deps (Podman names, pod infra, dependencies).
# Run with: ./test unit-quadlet-lifecycle

setup() {
    load stubs
    stubs-setup
    source "${FN}/quadlet/check-quadlet-names-free.sh"
    source "${FN}/quadlet/check-quadlet-deps.sh"
    D="${BATS_TEST_TMPDIR}/drop"
    SRC="${BATS_TEST_TMPDIR}/source"
    mkdir -p "${D}" "${SRC}"
}

@test "a free name passes" {
    : > "${D}/web.container"
    run check-quadlet-names-free "${D}/web.container" "${Q}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "a name taken in Podman is refused, per type" {
    : > "${STUB}/exists/network-front"
    : > "${D}/front.network"
    run check-quadlet-names-free "${D}/front.network" "${Q}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "front.network: a Podman network named front already exists" ]
    : > "${D}/front.volume"
    run check-quadlet-names-free "${D}/front.volume" "${Q}"
    [ "${status}" -eq 0 ]
}

@test "an image is not checked in Podman" {
    : > "${D}/web.image"
    run check-quadlet-names-free "${D}/web.image" "${Q}"
    [ "${status}" -eq 0 ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "a pod is refused when its infra container name is taken" {
    : > "${D}/web.pod"
    : > "${STUB}/exists/container-web-infra"
    run check-quadlet-names-free "${D}/web.pod" "${Q}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.pod: the container name web-infra, used by the pod for its infra container, is taken" ]
    rm "${STUB}/exists/container-web-infra"
    : > "${Q}/web-infra.container"
    run check-quadlet-names-free "${D}/web.pod" "${Q}"
    [ "${status}" -eq 1 ]
    rm "${Q}/web-infra.container"
    : > "${D}/web-infra.container"
    run check-quadlet-names-free "${D}/web.pod" "${Q}" "${D}"
    [ "${status}" -eq 1 ]
}

@test "a container named like the infra container of a pod is refused" {
    : > "${D}/web-infra.container"
    run check-quadlet-names-free "${D}/web-infra.container" "${Q}"
    [ "${status}" -eq 0 ]
    : > "${STUB}/exists/pod-web"
    run check-quadlet-names-free "${D}/web-infra.container" "${Q}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web-infra.container: web-infra is the infra container name of the pod web" ]
    rm "${STUB}/exists/pod-web"
    mkdir -p "${Q}/shop"
    : > "${Q}/shop/web.pod"
    run check-quadlet-names-free "${D}/web-infra.container" "${Q}"
    [ "${status}" -eq 1 ]
}

@test "a missing dependency is refused" {
    printf '[Container]\nNetwork=front.network\n' > "${D}/web.container"
    run check-quadlet-deps "${D}/web.container" "${Q}" "${SRC}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container needs front.network, which is not installed" ]
}

@test "a dependency installed, waiting in the source or in the same bundle passes" {
    printf '[Container]\nNetwork=front.network\nVolume=data.volume:/data\n' > "${D}/web.container"
    : > "${Q}/front.network"
    : > "${SRC}/data.volume.1761612345123456789"
    run check-quadlet-deps "${D}/web.container" "${Q}" "${SRC}" "${D}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "a missing Podman secret is refused, an existing one passes" {
    printf '[Container]\nSecret=db-password,type=env,target=DB\n' > "${D}/web.container"
    run check-quadlet-deps "${D}/web.container" "${Q}" "${SRC}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container needs the Podman secret db-password, which does not exist" ]
    : > "${STUB}/exists/secret-db-password"
    run check-quadlet-deps "${D}/web.container" "${Q}" "${SRC}"
    [ "${status}" -eq 0 ]
}

@test "plain names pass whether or not a matching quadlet is installed" {
    printf '[Container]\nNetwork=web\nNetwork=host\nVolume=data:/x\nMount=type=volume,source=data,destination=/m\n' > "${D}/app.container"
    run check-quadlet-deps "${D}/app.container" "${Q}" "${SRC}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    : > "${Q}/web.network"
    : > "${Q}/data.volume"
    run check-quadlet-deps "${D}/app.container" "${Q}" "${SRC}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "a container with Pod= is refused, as pods are not supported yet" {
    printf '[Container]\nContainerName=web\nPod=shop.pod\n' > "${D}/web.container"
    : > "${D}/shop.pod"
    run check-quadlet-deps "${D}/web.container" "${Q}" "${SRC}" "${D}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container: Pod= is not supported yet" ]
    printf '[Container]\nContainerName=web\nPod=shop\n' > "${D}/web.container"
    run check-quadlet-deps "${D}/web.container" "${Q}" "${SRC}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "web.container: Pod= is not supported yet" ]
}
