#!/usr/bin/env bats
# Unit test for is-tsv-config-name-sensitive (src/server/opt/podshift/fn/utils/is-tsv-config-name-sensitive.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/is-tsv-config-name-sensitive.sh"
    RULES="$(grep -v -e '^#' -e '^[[:space:]]*$' "${TST_PODSHIFT_DIR}/conf/tsv-rules.conf")"
}

@test "a listed whole word anywhere in the name is a secret" {
    for name in TSV_PASSWORD TSV_DB_PASSWORD TSV_PASSWD TSV_PSW TSV_PSWD TSV_PWD TSV_PASS TSV_DB_PASS_OLD TSV_SECRET TSV_SECRETS TSV_APP_SECRET TSV_TOKEN TSV_API_TOKEN TSV_GITHUB_TOKEN_2 TSV_APIKEY TSV_CREDENTIAL TSV_CREDENTIALS TSV_A__TOKEN TSV_TOKEN_; do
        run is-tsv-config-name-sensitive "${name}" "${RULES}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "KEY after API or PRIVATE is a secret" {
    for name in TSV_API_KEY TSV_PRIVATE_KEY TSV_STRIPE_API_KEY TSV_SSH_PRIVATE_KEY_FILE TSV_API__KEY; do
        run is-tsv-config-name-sensitive "${name}" "${RULES}"
        [ "${status}" -eq 0 ]
    done
}

@test "words that only contain a secret word are not secrets" {
    for name in TSV_PASSAGE TSV_KEYBOARD TSV_TOKENIZER_MODEL TSV_PASSPORT_URL TSV_COMPASS TSV_SECRETARY TSV_PWDX TSV_BYPASS TSV_APP TSV_DOMAIN; do
        run is-tsv-config-name-sensitive "${name}" "${RULES}"
        [ "${status}" -eq 1 ]
        [ -z "${output}" ]
    done
}

@test "KEY alone or after another word is not a secret" {
    for name in TSV_KEY TSV_SSH_KEY TSV_KEY_API TSV_PUBLIC_KEY TSV_API TSV_PRIVATE TSV_API_KEYS; do
        run is-tsv-config-name-sensitive "${name}" "${RULES}"
        [ "${status}" -eq 1 ]
    done
}

@test "a word from a given rules text is matched" {
    run is-tsv-config-name-sensitive TSV_PIN_CODE $'word PIN\nvalue ^x$'
    [ "${status}" -eq 0 ]
    run is-tsv-config-name-sensitive TSV_PIN_CODE $'word CODEX\nkey-after PIN'
    [ "${status}" -eq 1 ]
}

@test "empty rules or an empty name are not secrets" {
    run is-tsv-config-name-sensitive TSV_PASSWORD ""
    [ "${status}" -eq 1 ]
    run is-tsv-config-name-sensitive "" "${RULES}"
    [ "${status}" -eq 1 ]
    run is-tsv-config-name-sensitive TSV_ "${RULES}"
    [ "${status}" -eq 1 ]
}
