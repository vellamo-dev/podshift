#!/usr/bin/env bats
# Unit test for is-start-with-pod (src/server/opt/podshift/fn/quadlet/is-start-with-pod.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/is-start-with-pod.sh"
    Q="${BATS_TEST_TMPDIR}/web.container"
}

# The key is absent by default (returns false).
@test "no StartWithPod key returns 1 and prints nothing" {
    printf '[Container]\nImage=nginx\n' > "${Q}"
    run is-start-with-pod "${Q}"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

# All systemd true values are accepted.
@test "true, yes, 1 and on return 0 and print nothing" {
    for value in true yes 1 on; do
        printf '[Container]\nImage=nginx\nStartWithPod=%s\n' "${value}" > "${Q}"
        run is-start-with-pod "${Q}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

# True values are case-insensitive.
@test "the value is not case sensitive" {
    for value in TRUE True YES Yes ON On; do
        printf '[Container]\nStartWithPod=%s\n' "${value}" > "${Q}"
        run is-start-with-pod "${Q}"
        [ "${status}" -eq 0 ]
    done
}

# All systemd false values and empty return false.
@test "false, no, 0, off and an empty value return 1" {
    for value in false no 0 off ""; do
        printf '[Container]\nStartWithPod=%s\n' "${value}" > "${Q}"
        run is-start-with-pod "${Q}"
        [ "${status}" -eq 1 ]
    done
}

# Whitespace around the equals sign and the value is tolerated.
@test "spaces around the equal sign and the value are allowed" {
    printf '[Container]\n  StartWithPod = true  \n' > "${Q}"
    run is-start-with-pod "${Q}"
    [ "${status}" -eq 0 ]
}

# The last occurrence wins, like systemd.
@test "the last StartWithPod line wins" {
    printf '[Container]\nStartWithPod=true\nStartWithPod=false\n' > "${Q}"
    run is-start-with-pod "${Q}"
    [ "${status}" -eq 1 ]
    printf '[Container]\nStartWithPod=false\nStartWithPod=yes\n' > "${Q}"
    run is-start-with-pod "${Q}"
    [ "${status}" -eq 0 ]
}

# A similarly-named key is not mistaken for StartWithPod.
@test "another key that contains the name is not StartWithPod" {
    printf '[Container]\nXStartWithPod=true\n# StartWithPod=true\n' > "${Q}"
    run is-start-with-pod "${Q}"
    [ "${status}" -eq 1 ]
}

# A missing file returns false silently.
@test "missing file returns 1 and prints nothing" {
    run is-start-with-pod "${BATS_TEST_TMPDIR}/nope.container"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
