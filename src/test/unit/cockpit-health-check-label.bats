#!/usr/bin/env bats
# Unit test for cockpit-health-check-label (src/server/opt/podshift/cockpit/api/fn/cockpit-health-check-label.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/cockpit-health-check-label.sh"
}

@test "health-check label matches the CLI wording for mixed counts" {
    run cockpit-health-check-label "$(printf 'issues-found 22 2 1 0 0 1' | tr ' ' '\t')"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Issues found (22 passed, 2 issues, 1 warning, 1 note)" ]
}
