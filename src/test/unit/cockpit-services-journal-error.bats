#!/usr/bin/env bats
# Unit test for cockpit-services-journal-error (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-journal-error.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-journal-error.sh"
}

@test "insufficient permissions is an error with its line as the reason" {
    run cockpit-services-journal-error <<< 'No journal files were opened due to insufficient permissions.'
    [ "${status}" -eq 0 ]
    [ "${output}" = 'No journal files were opened due to insufficient permissions.' ]
}

@test "permission denied is an error; the reason is the first non-empty line, sanitized" {
    run cockpit-services-journal-error < <(printf '\n  Failed to open\t/var/log/journal/x/user-300.journal:   Permission denied\x1b[0m \nHint: more\n')
    [ "${status}" -eq 0 ]
    [ "${output}" = 'Failed to open /var/log/journal/x/user-300.journal: Permission denied [0m' ]
}

@test "the reason is cut to 200 characters" {
    run bash -c 'source "$1"; { printf "Access denied "; printf "a%.0s" $(seq 1 300); printf "\n"; } | cockpit-services-journal-error' _ "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-journal-error.sh"
    [ "${status}" -eq 0 ]
    [ "${#output}" -eq 200 ]
}

@test "no files found, a hint, -- No entries -- and empty stderr are not errors" {
    run cockpit-services-journal-error <<< 'No journal files were found.'
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    run cockpit-services-journal-error <<< 'Hint: You are currently not seeing messages from other users and the system.'
    [ "${status}" -eq 1 ]
    run cockpit-services-journal-error <<< '-- No entries --'
    [ "${status}" -eq 1 ]
    run cockpit-services-journal-error < /dev/null
    [ "${status}" -eq 1 ]
}
