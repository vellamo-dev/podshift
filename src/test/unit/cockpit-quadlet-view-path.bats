#!/usr/bin/env bats
# Unit test for cockpit-quadlet-view-path (src/server/opt/podshift/cockpit/api/fn/quadlets/cockpit-quadlet-view-path.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/quadlets/cockpit-quadlet-view-path.sh"
    QDIR=/home/podshift/.config/containers/systemd
}

@test "a Quadlet file in the folder prints its kind" {
    run cockpit-quadlet-view-path "${QDIR}/web.container" "${QDIR}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "container" ]
}

@test "a file in a bundle subfolder and a trailing slash on the folder are accepted" {
    run cockpit-quadlet-view-path "${QDIR}/app/db-net.network" "${QDIR}/"
    [ "${status}" -eq 0 ]
    [ "${output}" = "network" ]
}

@test "every Quadlet kind of services-list is known" {
    for kind in container pod kube network volume image build; do
        run cockpit-quadlet-view-path "${QDIR}/a.${kind}" "${QDIR}"
        [ "${status}" -eq 0 ]
        [ "${output}" = "${kind}" ]
    done
}

@test "an empty path, a unit file or a bare extension is not a Quadlet file" {
    run cockpit-quadlet-view-path "" "${QDIR}"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    run cockpit-quadlet-view-path /home/podshift/.config/systemd/user/web.service "${QDIR}"
    [ "${status}" -eq 1 ]
    run cockpit-quadlet-view-path "${QDIR}/.container" "${QDIR}"
    [ "${status}" -eq 1 ]
}

@test "a Quadlet file outside the folder prints its kind and exits 2" {
    run cockpit-quadlet-view-path /etc/containers/systemd/web.container "${QDIR}"
    [ "${status}" -eq 2 ]
    [ "${output}" = "container" ]
    run cockpit-quadlet-view-path "${QDIR}-other/web.container" "${QDIR}"
    [ "${status}" -eq 2 ]
}

@test "dot segments, empty segments and relative paths are refused" {
    run cockpit-quadlet-view-path "${QDIR}/../../web.container" "${QDIR}"
    [ "${status}" -eq 2 ]
    run cockpit-quadlet-view-path "${QDIR}/./web.container" "${QDIR}"
    [ "${status}" -eq 2 ]
    run cockpit-quadlet-view-path "${QDIR}//web.container" "${QDIR}"
    [ "${status}" -eq 2 ]
    run cockpit-quadlet-view-path web.container "${QDIR}"
    [ "${status}" -eq 2 ]
}

@test "an empty, relative or root folder is refused" {
    run cockpit-quadlet-view-path "${QDIR}/web.container" ""
    [ "${status}" -eq 2 ]
    run cockpit-quadlet-view-path "${QDIR}/web.container" "home/podshift"
    [ "${status}" -eq 2 ]
    run cockpit-quadlet-view-path /web.container /
    [ "${status}" -eq 2 ]
}
