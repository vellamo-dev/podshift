#!/usr/bin/env bats
# Unit test for health-render-json (src/server/opt/podshift/cli/modules/health-check/fn/health-render-json.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/fn/health-render-json.sh"
    verdict="$(printf 'issues-found\t1\t1\t0\t0\t0\t0')"
}

# One array per group, then the verdict and counts.
@test "one array per group, then the verdict and counts" {
    run health-render-json "$(printf 'host\tos\tOS\tOK\tFedora 44\nsecurity\tsshd\tSSH\tFAIL\tport 22')" "${verdict}" root
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"host":[{"id":"os","status":"OK","detail":"Fedora 44"}],"security":[{"id":"sshd","status":"FAIL","detail":"port 22"}],"verdict":"issues-found","caller":"root","passed":1,"issues":1,"warnings":0,"errors":0,"skipped":0,"notes":0}' ]
}

# Checks in the same group share one array.
@test "checks of one group share one array" {
    run health-render-json "$(printf 'host\tos\tOS\tOK\ta\nhost\tcpu\tCPU\tOK\tb')" "$(printf 'healthy\t2\t0\t0\t0\t0\t0')" podshift
    [ "${output}" = '{"host":[{"id":"os","status":"OK","detail":"a"},{"id":"cpu","status":"OK","detail":"b"}],"verdict":"healthy","caller":"podshift","passed":2,"issues":0,"warnings":0,"errors":0,"skipped":0,"notes":0}' ]
}

# JSON-special characters in a detail are escaped.
@test "quotes in a detail are escaped" {
    run health-render-json "$(printf 'host\tos\tOS\tWARN\tsay "hi"')" "$(printf 'needs-attention\t0\t0\t1\t0\t0\t0')" other
    [ "${output}" = '{"host":[{"id":"os","status":"WARN","detail":"say \"hi\""}],"verdict":"needs-attention","caller":"other","passed":0,"issues":0,"warnings":1,"errors":0,"skipped":0,"notes":0}' ]
}
