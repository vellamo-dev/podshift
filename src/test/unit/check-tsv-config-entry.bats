#!/usr/bin/env bats
# Unit test for check-tsv-config-entry (src/server/opt/podshift/fn/utils/check-tsv-config-entry.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/check-tsv-config-entry.sh"
    RULES="$(grep -v -e '^#' -e '^[[:space:]]*$' "${TST_PODSHIFT_DIR}/conf/tsv-rules.conf")"
    SECRET=$'Secrets don\'t belong in config. Use a Podman secret instead.'
}

@test "a good entry returns 0 and prints nothing" {
    run check-tsv-config-entry TSV_APP_DOMAIN example.com "${RULES}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "each problem gives its code" {
    run check-tsv-config-entry TSV_app x "${RULES}"
    [[ "${output}" == $'INVALID_NAME\t'* ]]
    run check-tsv-config-entry TSV_NW9 x "${RULES}"
    [[ "${output}" == $'RESERVED_NAME\t'* ]]
    run check-tsv-config-entry TSV_DB_PASSWORD x "${RULES}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "SENSITIVE_NAME"$'\t'"${SECRET}" ]
    run check-tsv-config-entry TSV_APP "" "${RULES}"
    [[ "${output}" == $'EMPTY_VALUE\t'* ]]
    run check-tsv-config-entry TSV_APP 'a"b' "${RULES}"
    [[ "${output}" == $'INVALID_VALUE\t'* ]]
    run check-tsv-config-entry TSV_APP AKIA""IOSFODNN7EXAMPLE "${RULES}"
    [ "${status}" -eq 1 ]
    [ "${output}" = "SENSITIVE_VALUE"$'\t'"${SECRET}" ]
}

@test "the name is checked before the value" {
    run check-tsv-config-entry TSV_ENV2 "" "${RULES}"
    [[ "${output}" == $'RESERVED_NAME\t'* ]]
    run check-tsv-config-entry TSV_API_TOKEN AKIA""IOSFODNN7EXAMPLE "${RULES}"
    [[ "${output}" == $'SENSITIVE_NAME\t'* ]]
}

@test "the value is never printed" {
    run check-tsv-config-entry TSV_APP "AKIA""IOSFODNN7EXAMPLE" "${RULES}"
    [[ "${output}" != *AKIA* ]]
    run check-tsv-config-entry TSV_APP 'my"value' "${RULES}"
    [[ "${output}" != *my* ]]
}
