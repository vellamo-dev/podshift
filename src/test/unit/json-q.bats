#!/usr/bin/env bats
# Unit test for json-q (src/server/opt/podshift/fn/utils/json-q.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/utils/json-q.sh"
}

# Wraps plain text in quotes.
@test "plain text is quoted" {
    run json-q "abc"
    [ "${output}" = '"abc"' ]
}

# Empty input becomes an empty JSON string.
@test "empty value is an empty string" {
    run json-q ""
    [ "${output}" = '""' ]
}

# Escapes the two JSON special characters.
@test "quote and backslash are escaped" {
    run json-q 'a"b\c'
    [ "${output}" = '"a\"b\\c"' ]
}

# Escapes control chars per JSON.
@test "tab and newline are escaped" {
    run json-q $'a\tb\nc'
    [ "${output}" = '"a\tb\nc"' ]
}
