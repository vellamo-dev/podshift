#!/usr/bin/env bats
# Stubbed tests for podshift network (src/server/opt/podshift/cli/modules/network) and the shared network helpers.
# The module runs from the source tree. The network facts, the config loaders and update-podshift-conf are stub
# functions; curl, ls for /sys/class/net, ip and cloud-init are fakes on PATH. Run with: ./test unit-cli-network

setup() {
    local here repo
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    PODSHIFT_DIR="${repo}/src/server/opt/podshift"
    MAIN="${PODSHIFT_DIR}/cli/modules/network/main.sh"
    STUB="${BATS_TEST_TMPDIR}/stub"
    mkdir -p "${STUB}/bin" "${STUB}/cloud"
    # curl reaches only quay.io and github.com.
    printf '#!/bin/bash\nfor a; do case "$a" in https://quay.io/|https://github.com/) exit 0 ;; esac; done\nexit 7\n' > "${STUB}/bin/curl"
    printf '#!/bin/bash\nif [ "$1" = /sys/class/net/ ]; then printf "eth0\\nlo\\nwlan0\\n"; else exec /bin/ls "$@"; fi\n' > "${STUB}/bin/ls"
    printf '#!/bin/bash\ncase "$*" in *"dev eth0"*|*"dev wlan0"*) echo "2: x inet 10.0.0.2/24" ;; esac\n' > "${STUB}/bin/ip"
    printf '#!/bin/bash\n' > "${STUB}/cloud/cloud-init"
    chmod +x "${STUB}/bin/"* "${STUB}/cloud/"*
    export STUB MAIN
}

# Runs the module with the stubs: $1 is stdin, the rest are the module arguments. S_* variables change the facts.
run_network() {
    local input
    input="${1}"
    shift
    run bash -c '
        nw-backend() { echo "${S_BACKEND-NetworkManager}"; }
        nw-device() { echo "${S_DEVICE-eth0}"; }
        nw-gateway() { echo "${S_GATEWAY-10.0.0.1}"; }
        nw-connection() { echo "${S_CONN-cloud-init-eth0}"; }
        nw-mode() { echo "${S_MODE-auto}"; }
        nw-ips() { printf "%b" "${S_IPS-1.2.3.4\n5.6.7.8\n}"; }
        load-podshift-conf-nw() { export TSV_NW1=1.2.3.4 TSV_NW2="5.6.7.8 x"; }
        load-podshift-conf-runtime() { PODSHIFT_NW_DEVICE="${S_CDEV-}"; PODSHIFT_NW_INITIALIZER="${S_CINIT-}"; }
        update-podshift-conf() { echo "WRITE $1=$2"; }
        load-podshift-conf-main() { PODSHIFT_REGISTRIES="${S_REG-quay.io,registry-1.docker.io,github.com}"; }
        source "${MAIN}" "$@" 2>&1
    ' bash "$@" <<<"${input}"
}

@test "examine prints the facts, the IPs as TSV_NW lines and the DHCP advice" {
    PATH="${STUB}/bin:${PATH}" run_network "" examine
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"  Mode       auto (DHCP)"* ]]
    [[ "${output}" == *"  TSV_NW2    5.6.7.8"* ]]
    [[ "${output}" == *"nmcli connection up cloud-init-eth0"* ]]
}

@test "no subcommand is examine; a static host with no route says so" {
    PATH="${STUB}/bin:${PATH}" S_MODE=manual S_DEVICE="" S_IPS="" run_network ""
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"  Device     none"* ]]
    [[ "${output}" == *"  IPs        none detected"* ]]
    [[ "${output}" == *"No default route found"* ]]
}

@test "examine --json prints one line of JSON" {
    PATH="${STUB}/bin:${PATH}" run_network "" examine --json
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"backend":"NetworkManager","connection":"cloud-init-eth0","device":"eth0","gateway":"10.0.0.1","mode":"auto","ips":["1.2.3.4","5.6.7.8"]}' ]
}

@test "print lists TSV_NW values and reload prints quoted export lines" {
    run_network "" print
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf 'TSV_NW1=1.2.3.4\nTSV_NW2=5.6.7.8 x')" ]
    run_network "" reload
    [ "${status}" -eq 0 ]
    [ "${lines[1]}" = "export TSV_NW1=1.2.3.4" ]
    [ "${lines[2]}" = 'export TSV_NW2=5.6.7.8\ x' ]
}

@test "check: some hosts unreachable is a warning, no route and no IP is a failure" {
    PATH="${STUB}/bin:${PATH}" S_MODE=manual run_network "" check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"    registry-1.docker.io  FAIL"* ]]
    [[ "${output}" == *"Result: WARN (1 warning)"* ]]
    PATH="${STUB}/bin:${PATH}" S_DEVICE="" S_IPS="" S_BACKEND=none S_MODE=x run_network "" check
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Result: FAIL (2 failure, 3 warning)"* ]]
}

@test "check probes exactly the hosts in PODSHIFT_REGISTRIES" {
    PATH="${STUB}/bin:${PATH}" S_MODE=manual S_REG="quay.io,github.com" run_network "" check
    [ "${status}" -eq 0 ]
    [ "$(grep -c '^    [^ ]*  \(OK\|FAIL\)$' <<< "${output}")" -eq 2 ]
    [[ "${output}" == *"    quay.io  OK"* ]]
    [[ "${output}" == *"    github.com  OK"* ]]
    [[ "${output}" == *"Result: OK"* ]]
    PATH="${STUB}/bin:${PATH}" S_REG="gitlab.com" run_network "" check
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"    gitlab.com  FAIL"* ]]
}

@test "check with PODSHIFT_REGISTRIES not set says so and counts it as a warning" {
    PATH="${STUB}/bin:${PATH}" S_MODE=manual S_REG="" run_network "" check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"    PODSHIFT_REGISTRIES is not set in main.conf"* ]]
    [ "$(grep -c '^    [^ ]*  \(OK\|FAIL\)$' <<< "${output}")" -eq 0 ]
    [[ "${output}" == *"Result: WARN (1 warning)"* ]]
}

@test "set refuses an unknown option and writes with --force without asking" {
    run_network "" set --bogus
    [ "${status}" -eq 1 ]
    [ "${output}" = "Unknown option: --bogus" ]
    run_network "" set --device eth9 --force
    [ "${status}" -eq 0 ]
    [ "${output}" = "WRITE PODSHIFT_NW_DEVICE=eth9" ]
    run_network "n" set --device eth9
    [ "${output}" = "Cancelled." ]
}

@test "set --initializer is accepted only for the active backend, but can still be confirmed" {
    run_network "y" set --initializer NetworkManager
    [ "${output}" = "WRITE PODSHIFT_NW_INITIALIZER=NetworkManager" ]
    S_BACKEND=systemd-networkd run_network "c" set --initializer NetworkManager
    [ "${output}" = "Cancelled." ]
}

@test "the device menu lists the devices without lo and writes the choice" {
    PATH="${STUB}/bin:${PATH}" run_network "$(printf '2\ny')" set
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"  1. eth0   (detected, current)"* ]]
    [[ "${output}" != *". lo"* ]]
    [[ "${output}" == *"WRITE PODSHIFT_NW_DEVICE=wlan0"* ]]
    PATH="${STUB}/bin:${PATH}" run_network "9" set
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Invalid selection."* ]]
}

@test "the initializer menu offers cloud-init first when it is present" {
    PATH="${STUB}/cloud:${STUB}/bin:${PATH}" run_network "$(printf '1\ny')" set --initializer
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"  1. cloud-init (cloud images, e.g. Hetzner)"* ]]
    [[ "${output}" == *"  2. NetworkManager (active)"* ]]
    [[ "${output}" == *"WRITE PODSHIFT_NW_INITIALIZER=cloud-init"* ]]
}

@test "fix repairs a wrong initializer and offers the device menu for a missing device" {
    PATH="${STUB}/bin:${PATH}" S_CINIT=bogus S_CDEV=eth7 run_network "$(printf '1\ny\nc\nc')" fix
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"The configured initializer 'bogus' is not detected on this system."* ]]
    [[ "${output}" == *"WRITE PODSHIFT_NW_INITIALIZER=NetworkManager"* ]]
    [[ "${output}" == *"The configured device 'eth7' does not exist (detected: eth0)."* ]]
    [[ "${output}" == *"Resulting state:"* ]]
}

@test "fix with a valid initializer does not ask about it" {
    PATH="${STUB}/bin:${PATH}" S_CINIT=NetworkManager run_network "c" fix
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"is not detected"* ]]
    [[ "${output}" != *"Detected initializers:"* ]]
}

@test "--help shows the network page and an unknown subcommand is an error" {
    run_network "" --help
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${PODSHIFT_DIR}/doc/help/network.md")" ]
    run_network "" nope
    [ "${status}" -eq 1 ]
    [ "${output}" = "Unknown network subcommand: nope. See 'podshift network --help'." ]
}

@test "nw-list-devices leaves out lo, and is-cloud-init-present follows the command" {
    source "${PODSHIFT_DIR}/fn/network/nw-list-devices.sh"
    source "${PODSHIFT_DIR}/fn/network/is-cloud-init-present.sh"
    PATH="${STUB}/bin:${PATH}" run nw-list-devices
    [ "${output}" = "$(printf 'eth0\nwlan0')" ]
    if [ ! -f /etc/cloud/cloud.cfg ]; then
        PATH="${STUB}/bin:/usr/bin:/bin" run is-cloud-init-present
        [ "${status}" -eq 1 ]
    fi
    PATH="${STUB}/cloud:${PATH}" run is-cloud-init-present
    [ "${status}" -eq 0 ]
}
