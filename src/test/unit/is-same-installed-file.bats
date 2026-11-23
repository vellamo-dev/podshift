#!/usr/bin/env bats
# Unit test for is-same-installed-file (src/server/opt/podshift/fn/quadlet/is-same-installed-file.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/is-same-installed-file.sh"
    D="${BATS_TEST_TMPDIR}"
    TSV_NW1="10.0.0"
}

@test "the same content is the same" {
    printf '[Container]\nContainerName=web\n' > "${D}/web.container"
    cp "${D}/web.container" "${D}/installed"
    run is-same-installed-file "${D}/web.container" "${D}/installed"
    [ "${status}" -eq 0 ]
}

@test "the dropped file is filled before the compare and is not changed" {
    printf 'Subnet=${TSV_NW1}.0/24\n' > "${D}/front.network"
    printf 'Subnet=10.0.0.0/24\n' > "${D}/installed"
    run is-same-installed-file "${D}/front.network" "${D}/installed"
    [ "${status}" -eq 0 ]
    grep -q 'TSV_NW1' "${D}/front.network"
}

@test "a different content is not the same" {
    printf 'Subnet=${TSV_NW1}.0/24\n' > "${D}/front.network"
    printf 'Subnet=10.0.1.0/24\n' > "${D}/installed"
    run is-same-installed-file "${D}/front.network" "${D}/installed"
    [ "${status}" -eq 1 ]
}

@test "a missing file returns 1" {
    printf 'a\n' > "${D}/a"
    run is-same-installed-file "${D}/a" "${D}/nope"
    [ "${status}" -eq 1 ]
    run is-same-installed-file "${D}/nope" "${D}/a"
    [ "${status}" -eq 1 ]
}

@test "drop ID lines are left out on both sides" {
    printf '# podshift-drop-id: 018bcfe5-6800-7000-8000-00000000000a\n[Container]\nContainerName=web\n' > "${D}/web.container"
    printf '# podshift-drop-id: 018bcfe5-6800-7000-8000-00000000000b\n[Container]\nContainerName=web\n' > "${D}/installed"
    run is-same-installed-file "${D}/web.container" "${D}/installed"
    [ "${status}" -eq 0 ]
    printf '[Container]\nContainerName=web\n' > "${D}/installed"
    run is-same-installed-file "${D}/web.container" "${D}/installed"
    [ "${status}" -eq 0 ]
    grep -q 'podshift-drop-id: 018bcfe5-6800-7000-8000-00000000000a' "${D}/web.container"
}

@test "other comment lines still count" {
    printf '# podshift-drop-id: 018bcfe5-6800-7000-8000-00000000000a\n# web\n[Container]\n' > "${D}/web.container"
    printf '# podshift-drop-id: 018bcfe5-6800-7000-8000-00000000000a\n[Container]\n' > "${D}/installed"
    run is-same-installed-file "${D}/web.container" "${D}/installed"
    [ "${status}" -eq 1 ]
}
