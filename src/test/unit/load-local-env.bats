#!/usr/bin/env bats
# Unit test for load-local-env (src/test/cli/shared/fn/tests/load-local-env.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${BATS_TEST_DIRNAME}/../cli/shared/fn/tests/load-local-env.sh"
    TEST_ROOT="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/load-local-env.XXXXXX")"
    unset RPM_VM_USER_PSW RPM_VM_OTHER RPM_VM_FOO RPM_VM_A RPM_VM_B RPM_VM_C RPM_VM_EQ
}

teardown() {
    unset RPM_VM_USER_PSW RPM_VM_OTHER RPM_VM_FOO RPM_VM_A RPM_VM_B RPM_VM_C RPM_VM_EQ
    rm -rf "${TEST_ROOT}"
}

# Missing .env must not fail or set keys.
@test "a missing .env file is a no-op" {
    run load-local-env "${TEST_ROOT}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    [ -z "${RPM_VM_USER_PSW+x}" ]
}

# Comments, blank lines and Windows line endings are skipped.
@test "comments and blank lines are ignored" {
    printf '%s\n' \
        '# RPM_VM_USER_PSW=from-comment' \
        '' \
        '  # also a comment' \
        $'RPM_VM_USER_PSW=from-file\r' \
        >"${TEST_ROOT}/.env"
    load-local-env "${TEST_ROOT}"
    [ "${RPM_VM_USER_PSW}" = "from-file" ]
}

# Keys that do not match RPM_VM_[A-Z0-9_]+ stay untouched.
@test "invalid keys are ignored" {
    printf '%s\n' \
        'SECRET=nope' \
        'rpm_vm_user_psw=nope' \
        'RPM_VM_=nope' \
        'RPM_VM_user=nope' \
        'export RPM_VM_FOO=nope' \
        'RPM_VM_FOO=yes' \
        >"${TEST_ROOT}/.env"
    load-local-env "${TEST_ROOT}"
    [ -z "${SECRET+x}" ]
    [ -z "${rpm_vm_user_psw+x}" ]
    [ -z "${RPM_VM_+x}" ]
    [ -z "${RPM_VM_user+x}" ]
    [ "${RPM_VM_FOO}" = "yes" ]
}

# Optional surrounding quotes are stripped; inner quotes stay.
@test "surrounding single or double quotes are stripped" {
    printf '%s\n' \
        'RPM_VM_A="double"' \
        "RPM_VM_B='single'" \
        'RPM_VM_C=unquoted' \
        'RPM_VM_OTHER="has '"'"'quote"' \
        >"${TEST_ROOT}/.env"
    load-local-env "${TEST_ROOT}"
    [ "${RPM_VM_A}" = "double" ]
    [ "${RPM_VM_B}" = "single" ]
    [ "${RPM_VM_C}" = "unquoted" ]
    [ "${RPM_VM_OTHER}" = "has 'quote" ]
}

# A value already in the environment is kept, even when empty.
@test "an existing environment value is not overridden" {
    export RPM_VM_USER_PSW="from-env"
    export RPM_VM_OTHER=""
    printf '%s\n' \
        'RPM_VM_USER_PSW=from-file' \
        'RPM_VM_OTHER=from-file' \
        'RPM_VM_FOO=from-file' \
        >"${TEST_ROOT}/.env"
    load-local-env "${TEST_ROOT}"
    [ "${RPM_VM_USER_PSW}" = "from-env" ]
    [ "${RPM_VM_OTHER}" = "" ]
    [ "${RPM_VM_FOO}" = "from-file" ]
}

# Equals signs in the value stay part of the value, and the key is exported.
@test "values are exported and may contain equals signs" {
    printf '%s\n' 'RPM_VM_EQ=a=b=c' >"${TEST_ROOT}/.env"
    load-local-env "${TEST_ROOT}"
    [ "${RPM_VM_EQ}" = "a=b=c" ]
    run bash -c 'printf %s "${RPM_VM_EQ}"'
    [ "${status}" -eq 0 ]
    [ "${output}" = "a=b=c" ]
}
