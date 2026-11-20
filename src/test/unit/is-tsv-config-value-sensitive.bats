#!/usr/bin/env bats
# Unit test for is-tsv-config-value-sensitive (src/server/opt/podshift/fn/utils/is-tsv-config-value-sensitive.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/is-tsv-config-value-sensitive.sh"
    RULES="$(grep -v -e '^#' -e '^[[:space:]]*$' "${TST_PODSHIFT_DIR}/conf/tsv-rules.conf")"
    A36="abcdefghijABCDEFGHIJ0123456789abcdef"
}

expect_secret() {
    run is-tsv-config-value-sensitive "${1}" "${RULES}"
    [ "${status}" -eq 0 ] || { echo "not a secret: ${1}"; return 1; }
    [ -z "${output}" ]
}

expect_plain() {
    run is-tsv-config-value-sensitive "${1}" "${RULES}"
    [ "${status}" -eq 1 ] || { echo "flagged: ${1}"; return 1; }
}

@test "private key headers are secrets" {
    expect_secret "-----BEGIN ""PRIVATE KEY-----"
    expect_secret "-----BEGIN RSA ""PRIVATE KEY-----"
    expect_secret "-----BEGIN OPENSSH ""PRIVATE KEY-----"
    expect_secret "-----BEGIN ENCRYPTED ""PRIVATE KEY-----"
    expect_secret "x -----BEGIN EC ""PRIVATE KEY----- y"
}

@test "public keys and certificates are not secrets" {
    expect_plain "-----BEGIN PUBLIC KEY-----"
    expect_plain "-----BEGIN CERTIFICATE-----"
    expect_plain "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl user@host"
}

@test "GitHub tokens are secrets" {
    expect_secret "ghp_${A36}"
    expect_secret "gho_${A36}"
    expect_secret "ghs_${A36}"
    expect_secret "https://x:ghp_${A36}@github.com/o/r.git"
    expect_secret "github""_pat_11ABCDEFG0123456789_abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWX"
}

@test "GitHub-like near misses are not secrets" {
    expect_plain "ghp_short"
    expect_plain "ghp_${A36}x"
    expect_plain "xghp_${A36}"
    expect_plain "ghx_${A36}"
    expect_plain "github""_pat_short"
}

@test "GitLab, Slack and AWS tokens are secrets" {
    expect_secret "glpat""-abcdefghij0123456789"
    expect_secret "glpat""-AbC_dEf-GhI_jKl-MnO_p"
    expect_secret "xox""b-123456789012-1234567890123-AbCdEfGhIjKlMnOpQrStUvWx"
    expect_secret "xox""p-1234-5678-9012-abcdef"
    expect_secret "AKIA""IOSFODNN7EXAMPLE"
    expect_secret "key=AKIA""IOSFODNN7EXAMPLE;"
}

@test "GitLab, Slack and AWS near misses are not secrets" {
    expect_plain "glpat""-short"
    expect_plain "xox""b-"
    expect_plain "xox""b-abc-def"
    expect_plain "xox""a-123-456-abc"
    expect_plain "AKIA""IOSFODNN7EXAMPL"
    expect_plain "AKIA""IOSFODNN7EXAMPLEX"
    expect_plain "XAKIA""IOSFODNN7EXAMPLE"
    expect_plain "AKIA""iosfodnn7example"
}

@test "JWTs are secrets" {
    expect_secret "ey""JhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ey""JzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
    expect_secret "Bearer ey""JhbGciOiJIUzI1NiJ9.ey""JzdWIiOiJhYmMifQ.c2lnbmF0dXJlLXBhcnQ"
}

@test "JWT-like near misses are not secrets" {
    expect_plain "ey""JhbGciOiJIUzI1NiJ9"
    expect_plain "ey""JhbGciOiJIUzI1NiJ9.ey""JzdWIiOiJhYmMifQ"
    expect_plain "ey""Jfoo.example.com"
    expect_plain "eyJ.a.b"
}

@test "UUIDs, digests, hashes and IDs are not secrets" {
    expect_plain "550e8400-e29b-41d4-a716-446655440000"
    expect_plain "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    expect_plain "quay.io/podman/hello@sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    expect_plain "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    expect_plain "0123456789abcdef0123456789abcdef01234567"
    expect_plain "4f3c2b1a0e9d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a9f8"
    expect_plain "QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVo="
    expect_plain "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"
}

@test "ordinary config values are not secrets" {
    expect_plain "example.com"
    expect_plain "16"
    expect_plain "https://example.com/path?x=1"
    expect_plain "postgres://db:5432/app"
}

@test "a pattern from a given rules text is matched and other lines are ignored" {
    run is-tsv-config-value-sensitive "pin-1234" $'word PIN\nvalue ^pin-[0-9]{4}$'
    [ "${status}" -eq 0 ]
    run is-tsv-config-value-sensitive "PIN" $'word PIN\nkey-after PIN'
    [ "${status}" -eq 1 ]
    run is-tsv-config-value-sensitive "ghp_${A36}" ""
    [ "${status}" -eq 1 ]
}
