#!/usr/bin/env bats
# Unit test for cockpit-images-quadlet-ref (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-images-quadlet-ref.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-images-quadlet-ref.sh"
}

@test "Image in the Image section is used" {
    run cockpit-images-quadlet-ref $'[Image]\nImage=docker.io/library/busybox:latest\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "docker.io/library/busybox:latest" ]
}

@test "ImageTag wins over Image" {
    run cockpit-images-quadlet-ref $'[Image]\nImage=docker.io/library/busybox@sha256:abc\nImageTag=localhost/busybox:pinned\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "localhost/busybox:pinned" ]
}

@test "a reference without a tag gets :latest, a registry port is not a tag" {
    run cockpit-images-quadlet-ref $'[Image]\nImage=registry.local:5000/team/app\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "registry.local:5000/team/app:latest" ]
    run cockpit-images-quadlet-ref $'[Image]\nImage=quay.io/app@sha256:0123\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "quay.io/app@sha256:0123" ]
}

@test "the last Image wins, spaces and quotes are trimmed" {
    run cockpit-images-quadlet-ref $'[Image]\nImage=first:1\n  Image = "docker.io/library/alpine:3.20"  \n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "docker.io/library/alpine:3.20" ]
}

@test "Image outside the Image section and in comments is ignored" {
    run cockpit-images-quadlet-ref $'[Unit]\nImage=wrong:1\n[Image]\n# Image=commented:1\n;Image=also:1\n'
    [ "${status}" -eq 1 ]
}

@test "an empty file returns 1" {
    run cockpit-images-quadlet-ref ""
    [ "${status}" -eq 1 ]
}
