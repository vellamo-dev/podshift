#!/usr/bin/env bats
# Stubbed tests for remove-item: refusals, stop order, podman quadlet rm, leftovers and volumes.
# Run with: ./test unit-quadlet-lifecycle

setup() {
    load stubs
    stubs-setup
    source "${FN}/quadlet/remove-item.sh"
}

@test "a name that is not installed returns 2 and logs no history" {
    run remove-item web.container "${Q}" 0 120
    [ "${status}" -eq 2 ]
    [ "${output}" = "web.container is not installed" ]
    [ -z "$(history-lines)" ]
    run remove-item ../web.container "${Q}" 0 120
    [ "${status}" -eq 2 ]
}

@test "a single container is stopped, removed and logged, not to the drop history" {
    printf '[Container]\nContainerName=web\n' > "${Q}/web.container"
    run remove-item web.container "${Q}" 0 120
    [ "${status}" -eq 0 ]
    [ ! -e "${Q}/web.container" ]
    grep -qx 'systemctl --user stop web.service' "${STUB}/calls.log"
    grep -qx 'podman quadlet rm --force web.container' "${STUB}/calls.log"
    [ -z "$(history-lines)" ]
    grep -qx "podshift-qdl-remove: stopping web.service" "${STUB}/logger.log"
    grep -qx "podshift-qdl-remove: removed web.container" "${STUB}/logger.log"
}

@test "a file used by another installed file is refused" {
    printf '[Network]\nNetworkName=front\n' > "${Q}/front.network"
    printf '[Container]\nNetwork=front.network\n' > "${Q}/web.container"
    run remove-item front.network "${Q}" 0 120
    [ "${status}" -eq 3 ]
    [ "${output}" = "used by web.container" ]
    [ -e "${Q}/front.network" ]
    [ "$(grep -c 'quadlet rm' "${STUB}/calls.log")" -eq 0 ]
    [ -z "$(history-lines)" ]
    grep -qx "podshift-qdl-remove: front.network: used by web.container" "${STUB}/logger.log"
}

@test "a network used by a plain Network= name is refused" {
    printf '[Network]\nNetworkName=web\n' > "${Q}/web.network"
    printf '[Container]\nContainerName=app\nNetwork=web\n' > "${Q}/app.container"
    run remove-item web.network "${Q}" 0 120
    [ "${status}" -eq 3 ]
    [ "${output}" = "used by app.container" ]
    [ -e "${Q}/web.network" ]
    [ "$(grep -c 'quadlet rm' "${STUB}/calls.log")" -eq 0 ]
}

@test "a network used by a container outside the item is refused" {
    printf '[Network]\nNetworkName=front\n' > "${Q}/front.network"
    printf 'manual\t\n' > "${STUB}/ps/network=front"
    run remove-item front.network "${Q}" 0 120
    [ "${status}" -eq 3 ]
    [ "${output}" = "used by container manual" ]
}

@test "an app is stopped users first, removed recursively, volumes kept" {
    mkdir -p "${Q}/shop"
    printf '[Network]\nNetworkName=shop\n' > "${Q}/shop/shop.network"
    printf '[Volume]\nVolumeName=data\n' > "${Q}/shop/data.volume"
    printf '[Container]\nNetwork=shop.network\nVolume=data.volume:/data\n' > "${Q}/shop/api.container"
    printf 'api\tapi.service\n' > "${STUB}/ps/network=shop"
    : > "${STUB}/exists/network-shop"
    : > "${STUB}/exists/volume-data"
    printf 'c0ffee\n' > "${STUB}/ps/label=PODMAN_SYSTEMD_UNIT=api.service"
    run remove-item shop "${Q}" 0 120
    [ "${status}" -eq 0 ]
    [ ! -e "${Q}/shop" ]
    [ "$(grep '^systemctl --user stop' "${STUB}/calls.log")" = "systemctl --user stop api.service"$'\n'"systemctl --user stop data-volume.service"$'\n'"systemctl --user stop shop-network.service" ]
    grep -qx 'podman quadlet rm --force --recursive shop' "${STUB}/calls.log"
    grep -qx 'podman rm -f c0ffee' "${STUB}/calls.log"
    grep -qx 'podman network rm shop' "${STUB}/calls.log"
    [ "$(grep -c 'podman volume rm' "${STUB}/calls.log")" -eq 0 ]
    grep -q 'kept the volume data' "${STUB}/logger.log"
    [ -z "$(history-lines)" ]
    grep -qx "podshift-qdl-remove: stopping api.service" "${STUB}/logger.log"
    grep -qx "podshift-qdl-remove: stopping shop-network.service" "${STUB}/logger.log"
    grep -qx "podshift-qdl-remove: removed shop" "${STUB}/logger.log"
}

@test "after podman quadlet rm the failed state of each removed unit is reset" {
    printf '[Container]\nContainerName=web\n' > "${Q}/web.container"
    run remove-item web.container "${Q}" 0 120
    [ "${status}" -eq 0 ]
    [ "$(grep -n -x 'podman quadlet rm --force web.container' "${STUB}/calls.log" | cut -d: -f1)" -lt \
        "$(grep -n -x 'systemctl --user reset-failed web.service' "${STUB}/calls.log" | cut -d: -f1)" ]
    mkdir -p "${Q}/shop"
    printf '[Network]\nNetworkName=shop\n' > "${Q}/shop/shop.network"
    printf '[Container]\nNetwork=shop.network\n' > "${Q}/shop/api.container"
    : > "${STUB}/calls.log"
    run remove-item shop "${Q}" 0 120
    [ "${status}" -eq 0 ]
    [ "$(grep '^systemctl --user reset-failed' "${STUB}/calls.log" | sort)" = "systemctl --user reset-failed api.service"$'\n'"systemctl --user reset-failed shop-network.service" ]
}

@test "with volumes the volume is removed too" {
    printf '[Volume]\nVolumeName=data\n' > "${Q}/data.volume"
    : > "${STUB}/exists/volume-data"
    run remove-item data.volume "${Q}" 1 120
    [ "${status}" -eq 0 ]
    grep -qx 'podman volume rm data' "${STUB}/calls.log"
}

@test "a pod is removed with --force after the files" {
    printf '[Pod]\nPodName=web\n' > "${Q}/web.pod"
    : > "${STUB}/exists/pod-web"
    run remove-item web.pod "${Q}" 0 120
    [ "${status}" -eq 0 ]
    grep -qx 'systemctl --user stop web-pod.service' "${STUB}/calls.log"
    grep -qx 'podman pod rm --force web' "${STUB}/calls.log"
}

@test "a failed podman quadlet rm returns 1 with the first error line" {
    printf '[Container]\nContainerName=web\n' > "${Q}/web.container"
    : > "${STUB}/fail-rm"
    run remove-item web.container "${Q}" 0 120
    [ "${status}" -eq 1 ]
    [ "${output}" = "podman quadlet rm failed: Error: quadlet is busy" ]
    [ -z "$(history-lines)" ]
    grep -qx "podshift-qdl-remove: podman quadlet rm failed for web.container" "${STUB}/logger.log"
    [ "$(grep -c 'reset-failed' "${STUB}/calls.log")" -eq 0 ]
}
