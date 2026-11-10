#!/usr/bin/env bats
# Unit test for health-render-tsv (src/server/opt/podshift/cli/modules/health-check/fn/health-render-tsv.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/fn/health-render-tsv.sh"
    results="$(printf 'host\tos\tOS\tOK\tFedora 44\nsecurity\tsshd\tSSH\tFAIL\tport 22')"
    verdict="$(printf 'issues-found\t1\t1\t0\t0\t0\t0')"
}

# Each check is one row: id, group, status, detail.
@test "one row per check: id, group, status, detail" {
    run health-render-tsv "${results}" "${verdict}" root
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "$(printf 'os\thost\tOK\tFedora 44')" ]
    [ "${lines[1]}" = "$(printf 'sshd\tsecurity\tFAIL\tport 22')" ]
}

# The final row is the verdict with caller and counts.
@test "last row is the verdict with the caller and counts" {
    run health-render-tsv "${results}" "${verdict}" podshift
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[2]}" = "$(printf 'verdict\tissues-found\tpodshift\t1\t0\t0\t0\t0')" ]
}
