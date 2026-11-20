#!/usr/bin/env bats
# Unit test for parse-tsv-conf-line (src/server/opt/podshift/fn/utils/parse-tsv-conf-line.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/parse-tsv-conf-line.sh"
    MARKER="${BATS_TEST_TMPDIR}/marker"
}

# Parses one line into k and v and prints rc|key|value.
parse() {
    local k="-" v="-" rc=0
    parse-tsv-conf-line "${1}" k v || rc=$?
    printf '%s|%s|%s' "${rc}" "${k}" "${v}"
}

@test "a plain value is read as it is" {
    [ "$(parse 'TSV_PG_VERSION=16')" = "0|TSV_PG_VERSION|16" ]
}

@test "one leading and one trailing single quote are removed" {
    [ "$(parse "TSV_APP_DOMAIN='example.com'")" = "0|TSV_APP_DOMAIN|example.com" ]
    [ "$(parse "TSV_A=''")" = "0|TSV_A|" ]
    [ "$(parse "TSV_A='a b'")" = "0|TSV_A|a b" ]
    [ "$(parse "TSV_A='x")" = "0|TSV_A|x" ]
}

@test "an escaped single quote is decoded, so a written value reads back the same" {
    local value written
    [ "$(parse "TSV_A='it'\\''s'")" = "0|TSV_A|it's" ]
    for value in "it's" "'" "a'" "'a" "''" "a'b'c"; do
        q="'"
        esc="'\\''"
        written="TSV_A='${value//"${q}"/${esc}}'"
        [ "$(parse "${written}")" = "0|TSV_A|${value}" ]
    done
}

@test "an = in the value is kept" {
    [ "$(parse "TSV_URL='https://example.com/?a=1&b=2'")" = "0|TSV_URL|https://example.com/?a=1&b=2" ]
    [ "$(parse 'TSV_A==x=')" = "0|TSV_A|=x=" ]
}

@test "command substitutions and variables stay literal and are not run" {
    [ "$(parse "TSV_A=\$(touch ${MARKER})")" = "0|TSV_A|\$(touch ${MARKER})" ]
    [ "$(parse "TSV_A='\`touch ${MARKER}\`'")" = "0|TSV_A|\`touch ${MARKER}\`" ]
    [ "$(parse 'TSV_A=${HOME}')" = '0|TSV_A|${HOME}' ]
    [ ! -e "${MARKER}" ]
}

@test "a trailing carriage return is ignored" {
    [ "$(parse "TSV_A='x'"$'\r')" = "0|TSV_A|x" ]
}

@test "comments and blank lines return 2" {
    for line in "# Custom TSV_* variables" "   # TSV_A=1" "" "   " $'\t'; do
        [ "$(parse "${line}")" = "2|-|-" ]
    done
}

@test "commands and other lines return 1 and set nothing" {
    for line in "touch ${MARKER}" "export PATH=/tmp" "PATH=/tmp" "TSV_A" "source /tmp/x" " TSV_A=1" "TSV_A =1" "export TSV_A=1"; do
        [ "$(parse "${line}")" = "1|-|-" ]
    done
    [ ! -e "${MARKER}" ]
}

@test "invalid names return 1" {
    for line in "TSV_=1" "TSV_a=1" "TSV_A-B=1" "TSV_A.B=1" "tsv_A=1" "TSVA=1" "TSV_Ä=1" "TSV_A\$(id)=1"; do
        [ "$(parse "${line}")" = "1|-|-" ]
    done
}
