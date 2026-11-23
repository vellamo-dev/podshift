#!/usr/bin/env bats
# Unit test for list-quadlet-deps (src/server/opt/podshift/fn/quadlet/list-quadlet-deps.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/list-quadlet-deps.sh"
    F="${BATS_TEST_TMPDIR}/web.container"
}

@test "quadlet references and secrets are listed, sorted, once each" {
    cat > "${F}" <<'Q'
[Container]
ContainerName=web
Image=web.image
Pod=web.pod
Network=front.network
Network=front.network:ip=10.0.0.5
Volume=data.volume:/data:Z
Mount=type=volume,source=logs.volume,destination=/logs
Mount=type=bind,src=cache.volume,dst=/cache
Secret=db-password,type=env,target=DB_PASSWORD
Q
    run list-quadlet-deps "${F}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "cache.volume"$'\n'"data.volume"$'\n'"front.network"$'\n'"logs.volume"$'\n'"secret:db-password"$'\n'"web.image"$'\n'"web.pod" ]
}

@test "paths, special networks, plain Pod= and registry images are not references" {
    cat > "${F}" <<'Q'
[Container]
Image=docker.io/library/busybox
Image=alpine:latest
Pod=web
Network=host
Network=none
Network=container:other
Network=ns:/run/netns/x
Network=slirp4netns:port_handler=slirp4netns
Volume=/srv/x:/x
Volume=./rel:/rel
Volume=/anon
Mount=type=tmpfs,destination=/tmp
Mount=type=bind,source=/srv/b,destination=/b
Q
    run list-quadlet-deps "${F}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "plain network and volume names are listed as plain references" {
    cat > "${F}" <<'Q'
[Container]
Network=web
Network=front:ip=10.0.0.5
Volume=data:/x
Volume=example-container-vol:/data:Z
Mount=type=volume,source=logs,destination=/logs
Q
    run list-quadlet-deps "${F}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "plain:data.volume"$'\n'"plain:example-container-vol.volume"$'\n'"plain:front.network"$'\n'"plain:logs.volume"$'\n'"plain:web.network" ]
}

@test "comments, Unit keys and continuation lines are skipped" {
    cat > "${F}" <<'Q'
[Unit]
Requires=db.service
After=other.network
[Container]
# Network=commented.network
; Volume=commented.volume
Exec=sh -c "echo \
  Network=inside.network"
  Network = spaced.network
Q
    run list-quadlet-deps "${F}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "spaced.network" ]
}

@test "a missing file returns 1" {
    run list-quadlet-deps "${BATS_TEST_TMPDIR}/nope"
    [ "${status}" -eq 1 ]
}
