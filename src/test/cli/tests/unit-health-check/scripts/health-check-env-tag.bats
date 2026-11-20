#!/usr/bin/env bats
# Unit test for health-check-env-tag (src/server/opt/podshift/cli/modules/health-check/checks/400-config/404-env-tag.sh).
# Run with: ./test unit-health-check

setup() {
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/checks/400-config/404-env-tag.sh"
    unset TSV_ENV
    load-podshift-conf-main() { :; }
    load-podshift-conf-runtime() { :; }
}

@test "a set environment tag is OK" {
    load-podshift-conf-runtime() { TSV_ENV=dev; }
    run health-check-env-tag
    [ "${status}" -eq 0 ]
    [ "${output}" = $'env-tag\tOK\tdev' ]
}

@test "an unset environment tag is a warning" {
    run health-check-env-tag
    [ "${status}" -eq 1 ]
    [ "${output}" = $'env-tag\tWARN\tnot set' ]
}
