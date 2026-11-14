#!/usr/bin/env bats
# Unit test for cockpit-inspect-image-ref (src/server/opt/podshift/cockpit/api/fn/inspect/cockpit-inspect-image-ref.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/inspect/cockpit-inspect-image-ref.sh"
    ALPINE="abbc135a7d39c0e8a2fdabbc135a7d39c0e8a2fdabbc135a7d39c0e8a2fd1234"
    BUSY="e1c50b84a672c4e6a8c0e1c50b84a672c4e6a8c0e1c50b84a672c4e6a8c05678"
    LIST="[{\"Id\":\"${ALPINE}\",\"Names\":[\"docker.io/library/alpine:latest\",\"docker.io/library/alpine:3.20\"]},
           {\"Id\":\"${ALPINE}\",\"Names\":[\"docker.io/library/alpine:latest\"]},
           {\"Id\":\"sha256:${BUSY}\",\"RepoTags\":[\"docker.io/library/busybox:latest\"]},
           {\"Id\":\"abbd000000000000\",\"Names\":null},
           {\"Id\":\"ffff00000000\",\"Names\":[\"<none>:<none>\"]}]"
}

@test "a 12-digit short ID resolves to the full ID and the first tag" {
    run cockpit-inspect-image-ref "${LIST}" abbc135a7d39
    [ "${status}" -eq 0 ]
    [ "${output}" = "${ALPINE}"$'\t'"docker.io/library/alpine:latest" ]
}

@test "the full ID, sha256: prefixes and upper case resolve too" {
    run cockpit-inspect-image-ref "${LIST}" "${BUSY}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${BUSY}"$'\t'"docker.io/library/busybox:latest" ]
    run cockpit-inspect-image-ref "${LIST}" "sha256:E1C50B84"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${BUSY}"$'\t'"docker.io/library/busybox:latest" ]
}

@test "an image without a valid tag gives an empty tag" {
    run cockpit-inspect-image-ref "${LIST}" ffff0000
    [ "${status}" -eq 0 ]
    [ "${output}" = "ffff00000000"$'\t' ]
}

@test "a prefix of two images, no match, or a name prints nothing" {
    run cockpit-inspect-image-ref "${LIST}" abb
    [ "${status}" -eq 1 ]
    run cockpit-inspect-image-ref "${LIST}" abbc
    [ "${status}" -eq 0 ]
    run cockpit-inspect-image-ref "${LIST}" abbd
    [ "${status}" -eq 0 ]
    [ "${output}" = "abbd000000000000"$'\t' ]
    run cockpit-inspect-image-ref "${LIST}" 0123456789ab
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    run cockpit-inspect-image-ref "${LIST}" alpine
    [ "${status}" -eq 1 ]
    run cockpit-inspect-image-ref "${LIST}" ab
    [ "${status}" -eq 1 ]
}

@test "bad JSON or an empty list fails" {
    run cockpit-inspect-image-ref 'not json' abbc135a7d39
    [ "${status}" -eq 1 ]
    run cockpit-inspect-image-ref '{}' abbc135a7d39
    [ "${status}" -eq 1 ]
    run cockpit-inspect-image-ref '[]' abbc135a7d39
    [ "${status}" -eq 1 ]
}
