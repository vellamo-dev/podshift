#!/usr/bin/env bats
# Stubbed tests for podshift selinux enforce. No VM, no network, no root.
# Fake getenforce and setenforce come from stubs/, and PODSHIFT_SELINUX_CONFIG points at a temp file.
# Run with: ./test unit-cli-selinux

setup() {
    local here repo
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    SCRIPT="${repo}/src/server/opt/podshift/cli/modules/selinux/main.sh"
    REQUIRE_ADMIN="${repo}/src/server/opt/podshift/fn/utils/require-admin.sh"
    STUBS="${here}/stubs"
    CONFIG="${BATS_TEST_TMPDIR}/selinux-config"
    SETENFORCE_LOG="${BATS_TEST_TMPDIR}/setenforce.log"
    unset STUB_GETENFORCE STUB_SETENFORCE CONFIRM_ANSWER
    rm -f "${SETENFORCE_LOG}"
    write_config "permissive"
}

write_config() {
    local value
    value="${1}"
    cat > "${CONFIG}" <<EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=${value}
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
EOF
}

config_mode() {
    awk '/^SELINUX=/ && !/^SELINUXTYPE=/ { print; exit }' "${CONFIG}"
}

run_as_admin() {
    run env PATH="${STUBS}:/usr/bin:/bin" \
        PODSHIFT_SELINUX_CONFIG="${CONFIG}" \
        STUB_GETENFORCE="${STUB_GETENFORCE-Enforcing}" \
        STUB_SETENFORCE="${STUB_SETENFORCE-}" \
        SETENFORCE_LOG="${SETENFORCE_LOG}" \
        CONFIRM_ANSWER="${CONFIRM_ANSWER-}" \
        bash -c '
            require-admin() { return 0; }
            is-interactive-output() { return 1; }
            source "$1" || exit 1
            shift
            if [ -n "${CONFIRM_ANSWER}" ]; then
                printf "%s\n" "${CONFIRM_ANSWER}" | podshift-selinux "$@"
            else
                podshift-selinux "$@"
            fi
        ' bash "${SCRIPT}" "$@"
}

run_as_user() {
    run env PATH="${STUBS}:/usr/bin:/bin" \
        PODSHIFT_SELINUX_CONFIG="${CONFIG}" \
        STUB_GETENFORCE="${STUB_GETENFORCE-Enforcing}" \
        SETENFORCE_LOG="${SETENFORCE_LOG}" \
        REQUIRE_ADMIN="${REQUIRE_ADMIN}" \
        bash -c '
            is-admin() { return 1; }
            is-interactive-output() { return 1; }
            source "${REQUIRE_ADMIN}" || exit 1
            source "$1" || exit 1
            shift
            podshift-selinux "$@"
        ' bash "${SCRIPT}" "$@"
}

@test "already enforcing, config enforcing: nothing changes" {
    write_config "enforcing"
    export STUB_GETENFORCE=Enforcing
    run_as_admin enforce --force
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"SELinux is already enforcing. Nothing to do."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
}

@test "already enforcing, config permissive, --force: updates the config only" {
    write_config "permissive"
    export STUB_GETENFORCE=Enforcing
    run_as_admin enforce --force
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"is now set to enforcing so the mode survives a reboot."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
    grep -q 'SELINUXTYPE=targeted' "${CONFIG}"
    grep -q 'This file controls the state of SELinux' "${CONFIG}"
}

@test "already enforcing, config permissive, confirm yes: updates the config" {
    write_config "permissive"
    export STUB_GETENFORCE=Enforcing
    export CONFIRM_ANSWER=yes
    run_as_admin enforce
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"is now set to enforcing so the mode survives a reboot."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
}

@test "already enforcing, config permissive, confirm no: cancelled" {
    write_config "permissive"
    export STUB_GETENFORCE=Enforcing
    export CONFIRM_ANSWER=no
    run_as_admin enforce
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Cancelled."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}

@test "permissive, --force: switches the mode and updates the config" {
    write_config "permissive"
    export STUB_GETENFORCE=Permissive
    run_as_admin enforce --force
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"SELinux is now enforcing. The mode is also set in ${CONFIG}."* ]]
    [ -f "${SETENFORCE_LOG}" ]
    [ "$(cat "${SETENFORCE_LOG}")" = "1" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
    grep -q 'SELINUXTYPE=targeted' "${CONFIG}"
}

@test "permissive, confirm yes: switches the mode and updates the config" {
    write_config "permissive"
    export STUB_GETENFORCE=Permissive
    export CONFIRM_ANSWER=y
    run_as_admin enforce
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"SELinux is now enforcing."* ]]
    [ "$(cat "${SETENFORCE_LOG}")" = "1" ]
    [ "$(config_mode)" = "SELINUX=enforcing" ]
}

@test "permissive, confirm no: cancelled, nothing changes" {
    write_config "permissive"
    export STUB_GETENFORCE=Permissive
    export CONFIRM_ANSWER=c
    run_as_admin enforce
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Cancelled."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}

@test "disabled: prints the steps and changes nothing" {
    write_config "disabled"
    export STUB_GETENFORCE=Disabled
    run_as_admin enforce --force
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"SELinux is disabled. Nothing changed."* ]]
    [[ "${output}" == *"SELINUX=permissive, in ${CONFIG}"* ]]
    [[ "${output}" == *"touch /.autorelabel"* ]]
    [[ "${output}" == *"Reboot."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=disabled" ]
}

@test "not root: unauthorised, nothing changes" {
    write_config "permissive"
    export STUB_GETENFORCE=Permissive
    run_as_user enforce --force
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Unauthorised. Root privileges required."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}

@test "unknown subcommand: error" {
    export STUB_GETENFORCE=Permissive
    run_as_admin port
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Unknown selinux subcommand: port. See 'podshift --help selinux'."* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
}

@test "missing subcommand: error" {
    run_as_admin
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Unknown selinux subcommand: . See 'podshift --help selinux'."* ]]
}

@test "unknown option: usage" {
    export STUB_GETENFORCE=Permissive
    run_as_admin enforce --please
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Usage: podshift selinux enforce [--force]"* ]]
    [ ! -f "${SETENFORCE_LOG}" ]
    [ "$(config_mode)" = "SELINUX=permissive" ]
}
