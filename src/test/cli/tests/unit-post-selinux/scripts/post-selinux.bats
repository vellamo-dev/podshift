#!/usr/bin/env bats
# Stubbed tests for the post enforce-selinux step. No VM, no network, no root.
# Fake getenforce, setenforce and selinuxenabled come from stubs/.
# PODSHIFT_SELINUX_CONFIG and PODSHIFT_DESKTOP_FLAG point at temp files.
# Run with: ./test unit-post-selinux

setup() {
    HERE="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    REPO="${HERE}"
    while [ "${REPO}" != "/" ] && [ ! -f "${REPO}/podshift.spec" ]; do
        REPO="$(dirname "${REPO}")"
    done
    SCRIPT="${REPO}/src/server/opt/podshift/rpm/post/enforce-selinux.sh"
    STUBS="${HERE}/stubs"
    CONFIG="${BATS_TEST_TMPDIR}/selinux-config"
    DESKTOP="${BATS_TEST_TMPDIR}/desktop"
    SETENFORCE_LOG="${BATS_TEST_TMPDIR}/setenforce.log"
    ACTION=1
    unset STUB_GETENFORCE STUB_SETENFORCE STUB_SELINUXENABLED
    rm -f "${SETENFORCE_LOG}" "${DESKTOP}"
    write_config "permissive"
}

write_config() {
    local value
    value="${1}"
    cat > "${CONFIG}" <<CFG
# This file controls the state of SELinux on the system.
SELINUX=${value}
SELINUXTYPE=targeted
CFG
}

config_mode() {
    awk '/^SELINUX=/ && !/^SELINUXTYPE=/ { print; exit }' "${CONFIG}"
}

run_step() {
    run env PATH="${STUBS}:/usr/bin:/bin" \
        PODSHIFT_SELINUX_CONFIG="${CONFIG}" \
        PODSHIFT_DESKTOP_FLAG="${DESKTOP}" \
        STUB_GETENFORCE="${STUB_GETENFORCE-Permissive}" \
        STUB_SETENFORCE="${STUB_SETENFORCE-}" \
        STUB_SELINUXENABLED="${STUB_SELINUXENABLED-1}" \
        SETENFORCE_LOG="${SETENFORCE_LOG}" \
        bash -c '
            source "$1" || exit 1
            enforce-selinux "$2"
        ' bash "${SCRIPT}" "${ACTION}"
}

@test "install server, permissive: switches the mode" {
    export STUB_GETENFORCE=Permissive
    run_step
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Switched SELinux from permissive to enforcing"* ]]
    [ -f "${SETENFORCE_LOG}" ]
    [ "$(cat "${SETENFORCE_LOG}")" = "1" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
    [[ "${output}" == *"[OK] Done"* ]]
}

@test "install server, enforcing: leaves the mode" {
    write_config "enforcing"
    export STUB_GETENFORCE=Enforcing
    run_step
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Already enforcing"* ]]
    [[ "${output}" != *"Switched SELinux from permissive to enforcing"* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
}

@test "install server, disabled: warns and changes nothing" {
    write_config "disabled"
    export STUB_GETENFORCE=Disabled
    export STUB_SELINUXENABLED=0
    run_step
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[WARN] SELinux is disabled, run podshift selinux enforce for the steps to turn it back on"* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=disabled" ]
}

@test "desktop install: skips the switch" {
    touch "${DESKTOP}"
    export STUB_GETENFORCE=Permissive
    run_step
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Skipped on desktop install"* ]]
    [[ "${output}" != *"Switched SELinux from permissive to enforcing"* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}

@test "upgrade: skips the switch" {
    ACTION=2
    export STUB_GETENFORCE=Permissive
    run_step
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Skipped on upgrade"* ]]
    [[ "${output}" != *"Switched SELinux from permissive to enforcing"* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}

@test "failed switch: warns and is not fatal" {
    export STUB_GETENFORCE=Permissive
    export STUB_SETENFORCE=fail
    run_step
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[WARN] failed to switch SELinux to enforcing"* ]]
    [ -f "${SETENFORCE_LOG}" ]
    [ "$(cat "${SETENFORCE_LOG}")" = "1" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}
