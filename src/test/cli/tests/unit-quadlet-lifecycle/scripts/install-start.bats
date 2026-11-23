#!/usr/bin/env bats
# Stubbed tests for install-quadlet and start-quadlet: install once, never --replace, start only.
# Run with: ./test unit-quadlet-lifecycle

setup() {
    load stubs
    stubs-setup
    source "${FN}/quadlet/install-quadlet.sh"
    source "${FN}/quadlet/start-quadlet.sh"
    S="${BATS_TEST_TMPDIR}/staged"
    mkdir -p "${S}"
}

@test "a single file is installed without --replace" {
    printf '[Container]\nContainerName=web\n' > "${S}/web.container"
    run install-quadlet "${S}/web.container"
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "podman quadlet install ${S}/web.container" ]
}

@test "a bundle folder is installed as an application without --replace" {
    mkdir -p "${S}/shop.qdl-bundle"
    run install-quadlet "${S}/shop.qdl-bundle"
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "podman quadlet install --application shop ${S}/shop.qdl-bundle" ]
}

@test "a failed install returns 1 and logs the Podman output" {
    : > "${STUB}/fail-install"
    printf '[Container]\nContainerName=web\n' > "${S}/web.container"
    run install-quadlet "${S}/web.container"
    [ "${status}" -eq 1 ]
    grep -q 'podshift-qdl-install: Error: a quadlet with that name already exists' "${STUB}/logger.log"
}

@test "start queues a start, never a restart, the pod before the container" {
    mkdir -p "${S}/app"
    printf '[Pod]\nPodName=web\n' > "${S}/app/web.pod"
    printf '[Container]\nContainerName=api\n' > "${S}/app/api.container"
    run start-quadlet "${S}/app"
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "systemctl --user start --no-block web-pod.service"$'\n'"systemctl --user start --no-block api.service" ]
}
