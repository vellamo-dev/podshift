#!/usr/bin/env bats
# Unit test for check-tsv-config-name (src/server/opt/podshift/fn/utils/check-tsv-config-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/check-tsv-config-name.sh"
}

@test "good custom names return 0 and print nothing" {
    for name in TSV_APP TSV_A TSV_APP_DOMAIN TSV_PG_VERSION TSV_A1 TSV_A_ TSV_A__B TSV_N TSV_NAME TSV_EN TSV_E TSV_NEW; do
        run check-tsv-config-name "${name}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "names that are not TSV_ plus a capital letter are INVALID_NAME" {
    for name in "" TSV_ TSV TSV_app TSV_App APP_NAME tsv_APP TSV_1APP TSV__APP "TSV_A B" TSV_A-B TSV_A.B TSV_Ä "TSV_A"$'\n' PODSHIFT_NW_DEVICE; do
        run check-tsv-config-name "${name}"
        [ "${status}" -eq 1 ]
        [[ "${output}" == $'INVALID_NAME\t'* ]]
    done
}

@test "the message names the key and the rule" {
    run check-tsv-config-name TSV_app
    [ "${status}" -eq 1 ]
    [ "${output}" = $'INVALID_NAME\tInvalid name \'TSV_app\'. Use TSV_ followed by a capital letter, then capital letters, digits or _.' ]
}

@test "names starting with TSV_NW or TSV_ENV are RESERVED_NAME" {
    for name in TSV_NW1 TSV_NW8 TSV_NW9 TSV_NW TSV_NWORDER TSV_NW_X TSV_ENV TSV_ENV2 TSV_ENVIRONMENT TSV_ENV_NAME; do
        run check-tsv-config-name "${name}"
        [ "${status}" -eq 1 ]
        [ "${output}" = "RESERVED_NAME"$'\t'"Name '${name}' is reserved. Names starting with TSV_NW or TSV_ENV are managed by PodShift." ]
    done
}

@test "no argument is INVALID_NAME" {
    run check-tsv-config-name
    [ "${status}" -eq 1 ]
    [[ "${output}" == $'INVALID_NAME\t'* ]]
}
