#!/usr/bin/env bats
# Unit test for cockpit-health-check-data (src/server/opt/podshift/cockpit/api/fn/cockpit-health-check-data.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/cockpit-health-check-data.sh"
    GROUPS_CONF="${TST_PODSHIFT_DIR}/cli/modules/health-check/groups.conf"
}

# $1 result lines (use | as TAB), $2 verdict line (space separated)
payload() {
    local results
    results="$(printf '%s' "${1}" | tr '|' '\t')"
    cockpit-health-check-data "${results}" "$(printf '%s' "${2}" | tr ' ' '\t')" "${GROUPS_CONF}"
}

@test "healthy results become ok rows and a Healthy label" {
    run payload $'host|os|OS|OK|Fedora Linux 45\nhost|kernel|Kernel|OK|7.3.3\nruntime|podman|Podman|OK|installed' "healthy 3 0 0 0 0 0"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.groups | length) == 2
        and .groups[0].id == "host"
        and .groups[0].label == "Host"
        and .groups[1].id == "runtime"
        and .groups[1].label == "Runtime"
        and .groups[0].rows[0] == {"id":"os","label":"OS","state":"ok","value":"Fedora Linux 45","fix":null}
        and .groups[0].rows[1].id == "kernel"
        and .groups[1].rows[0].id == "podman"
        and .summary == {"state":"ok","label":"Healthy (3 passed)","passed":3,"notes":0,"warnings":0,"failed":0}
    '
}

@test "INFO, WARN, FAIL, SKIP and ERROR map to note, warn, fail, and fix is kept" {
    run payload $'config|config-files|Config files|INFO|no custom keys yet|podshift --help config\nsecurity|ssh-config|SSH|WARN|password login|tighten sshd\nruntime|failed-units|Failed units|FAIL|3 failed|journalctl -p err\nhost|disk|Disk space|SKIP|needs root|\nnetwork|registries|Registries|ERROR|timed out|' "incomplete 0 1 1 1 1 1"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .groups[0].id == "config" and .groups[0].label == "Configuration"
        and .groups[0].rows[0].state == "note"
        and .groups[0].rows[0].fix == "podshift --help config"
        and .groups[1].label == "Security"
        and .groups[1].rows[0].state == "warn"
        and .groups[1].rows[0].fix == "tighten sshd"
        and .groups[2].rows[0].state == "fail"
        and .groups[2].rows[0].fix == "journalctl -p err"
        and .groups[3].rows[0].state == "note"
        and .groups[3].rows[0].fix == null
        and .groups[4].label == "Network and monitoring"
        and .groups[4].rows[0].state == "fail"
        and .summary.state == "fail"
        and .summary.failed == 1
        and .summary.notes == 1
        and .summary.warnings == 1
        and .summary.label == "Check incomplete (1 issue, 1 warning, 1 note, 1 check could not run, 1 skipped)"
    '
}

@test "needs-attention and issues-found pick warn and fail summary states" {
    run payload $'host|os|OS|WARN|low disk|free some space' "needs-attention 0 0 1 0 0 0"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .summary.state == "warn"
        and .summary.label == "Needs attention (1 warning)"
        and .summary.warnings == 1
        and .summary.failed == 0
    '

    run payload $'host|os|OS|FAIL|broken|repair it' "issues-found 0 1 0 0 0 0"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .summary.state == "fail"
        and .summary.label == "Issues found (1 issue)"
        and .summary.failed == 1
    '
}

@test "Environment tag set is ok and unset is a warning with the env fix" {
    run payload $'config|env-tag|Environment tag|OK|dev\n' "healthy 1 0 0 0 0 0"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .groups[0].rows[0] == {"id":"env-tag","label":"Environment tag","state":"ok","value":"dev","fix":null}
        and .summary.state == "ok"
        and .summary.passed == 1
    '

    run payload $'config|env-tag|Environment tag|WARN|not set|sudo podshift env --set <env>\n' "needs-attention 0 0 1 0 0 0"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .groups[0].rows[0].id == "env-tag"
        and .groups[0].rows[0].state == "warn"
        and .groups[0].rows[0].value == "not set"
        and .groups[0].rows[0].fix == "sudo podshift env --set <env>"
        and .summary.state == "warn"
        and .summary.warnings == 1
        and .summary.label == "Needs attention (1 warning)"
    '
}
