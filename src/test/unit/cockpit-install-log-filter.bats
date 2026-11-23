#!/usr/bin/env bats
# Unit test for cockpit-install-log-filter (src/server/opt/podshift/cockpit/api/fn/drop/cockpit-install-log-filter.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/drop/cockpit-install-log-filter.sh"
    HC="2c6fce7021d6656f45a2b474b2cbc7df21ef1854586d9e43a244ee65097ba187"
    QUEUED="$(line podshift-qdl-install "" "queued start of boy.service")"
}

# line <identifier> <user unit or empty> <message>: one journalctl -o json line.
line() {
    jq -n -c --arg i "${1}" --arg u "${2}" --arg m "${3}" \
        '{__REALTIME_TIMESTAMP: "1794474134000000", SYSLOG_IDENTIFIER: $i, MESSAGE: $m} + (if $u == "" then {} else {USER_UNIT: $u} end)'
}

@test "no input gives no output" {
    run cockpit-install-log-filter < /dev/null
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "pipeline tag lines are kept as they are" {
    local input
    input="$(line podshift-qdl-install "" "installed boy.container"; line podshift-drop-process "" "accepted boy.container")"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${input}" ]
}

@test "systemd lines of an installed unit are kept, also when they come before the queued start line" {
    local input
    input="$(
        line systemd boy.service "Starting boy.service - Busybox Boy..."
        printf '%s\n' "${QUEUED}"
        line systemd boy.service "boy.service: Failed with result 'exit-code'."
    )"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${input}" ]
}

@test "systemd lines of a unit that PodShift did not install are left out" {
    local input
    input="$(
        line systemd boy.service "Started boy.service - Busybox Boy."
        line systemd example-container.service "Started example-container.service - PodShift example container."
        line systemd example-quadlet-network.service "Finished example-quadlet-network.service - PodShift example Quadlet network."
    )"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "user manager start, libpod scope, podshift, run and health check lines are left out" {
    local input
    input="$(
        printf '%s\n' "${QUEUED}"
        line systemd dbus.socket "Listening on dbus.socket - D-Bus User Message Bus Socket."
        line systemd default.target "Reached target default.target - Main User Target."
        line systemd session.slice "Created slice session.slice - User Core Session Slice."
        line systemd systemd-tmpfiles-setup.service "Finished systemd-tmpfiles-setup.service - Create User Files and Directories."
        line systemd podman-user-wait-network-online.service "Finished podman-user-wait-network-online.service."
        line systemd podman-auto-update.timer "Started podman-auto-update.timer - Podman auto-update timer."
        line systemd podman.socket "Listening on podman.socket - Podman API Socket."
        line systemd podman-pause-98f775c4.scope "Started podman-pause-98f775c4.scope."
        line systemd "libpod-${HC}.scope" "Started libpod-${HC}.scope - libcrun container."
        line systemd podshift-api-36461-3669.service "Started podshift-api-36461-3669.service"
        line systemd run-p38546-i38246.service "run-p38546-i38246.service: Main process exited"
        line systemd "${HC}-5e3c1a.service" "Started ${HC}-5e3c1a.service"
        line systemd "" "Reloading..."
        line systemd boy.service "Started boy.service - Busybox Boy."
    )"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${QUEUED}
$(line systemd boy.service "Started boy.service - Busybox Boy.")" ]
}

@test "podman lines are kept only for container events of an installed unit" {
    local keep input
    keep="container start ${HC} (image=docker.io/library/busybox:latest, name=boy, PODMAN_SYSTEMD_UNIT=boy.service)"
    input="$(
        printf '%s\n' "${QUEUED}"
        line podman "" "image pull d2482869a6b8 docker.io/library/busybox:latest"
        line podman "" "${keep}"
        line podman "" "container start ${HC} (image=docker.io/library/busybox:latest, name=boyz, PODMAN_SYSTEMD_UNIT=boy.servicez)"
        line podman "" "container start ${HC} (image=docker.io/library/alpine:latest, name=example-container, PODMAN_SYSTEMD_UNIT=example-container.service, podshift.example=1)"
        line podman "" "container health_status ${HC} (image=docker.io/library/busybox:latest, name=boy, health_status=healthy, PODMAN_SYSTEMD_UNIT=boy.service)"
        line podman "" "container exec_died ${HC} (image=docker.io/library/busybox:latest, name=boy, PODMAN_SYSTEMD_UNIT=boy.service)"
    )"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${QUEUED}
$(line podman "" "${keep}")" ]
}

@test "lines of a removed Quadlet file and of the units a removal names are kept" {
    local input
    input="$(
        line podshift-qdl-remove "" "removing web.container"
        line podshift-qdl-remove "" "stopping api.service"
        line podshift-qdl-remove "" "removing front.network"
        line systemd web.service "Stopped web.service - Web."
        line systemd api.service "Stopping api.service - API..."
        line systemd front-network.service "Stopped front-network.service."
        line podman "" "container remove ${HC} (image=docker.io/library/nginx:latest, name=web, PODMAN_SYSTEMD_UNIT=web.service)"
    )"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${input}" ]
}

@test "a refused removal does not add the units it names" {
    local refused input
    refused="$(line podshift-qdl-remove "" "front.network: used by web.container")"
    input="$(
        printf '%s\n' "${refused}"
        line systemd web.service "Started web.service - Web."
        line systemd front-network.service "Started front-network.service."
    )"
    run cockpit-install-log-filter <<< "${input}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${refused}" ]
}

@test "lines that are not JSON objects are skipped and the order is kept" {
    local a b
    a="$(line podshift-qdl-install "" "installing boy.container")"
    b="$(line systemd boy.service "Started boy.service - Busybox Boy.")"
    run cockpit-install-log-filter <<< "-- No entries --
${a}
not json {
[1,2]
${b}
${QUEUED}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${a}
${b}
${QUEUED}" ]
}
