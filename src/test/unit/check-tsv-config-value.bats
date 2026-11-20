#!/usr/bin/env bats
# Unit test for check-tsv-config-value (src/server/opt/podshift/fn/utils/check-tsv-config-value.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/check-tsv-config-value.sh"
}

@test "ordinary values return 0 and print nothing" {
    for value in 16 example.com "a b" "https://example.com/a?b=1&c=2" '50%' '$HOME' '${TSV_X}' 'a\b' "quay.io/app:1.2" "x=y" "Ä" " lead"; do
        run check-tsv-config-value "${value}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "an empty value is EMPTY_VALUE" {
    run check-tsv-config-value ""
    [ "${status}" -eq 1 ]
    [ "${output}" = $'EMPTY_VALUE\tValue must not be empty.' ]
    run check-tsv-config-value
    [ "${status}" -eq 1 ]
    [[ "${output}" == $'EMPTY_VALUE\t'* ]]
}

@test "quotes, control characters and a trailing backslash are INVALID_VALUE" {
    for value in 'a"b' '"' "it's" "'" $'a\nb' $'a\tb' $'\r' $'a\x01' $'a\x7f' $'a\x1b[0m' 'end\' '\'; do
        run check-tsv-config-value "${value}"
        [ "${status}" -eq 1 ]
        [ "${output}" = $'INVALID_VALUE\tValue must not contain quotes (" or \'), control characters or a trailing backslash.' ]
    done
}
